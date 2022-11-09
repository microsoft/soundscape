//
//  CustomPageViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol CustomPageViewControllerDelegate: AnyObject {
    func pageChanged()
}

class CustomPageViewController: UIViewController {
    weak var delegate: CustomPageViewControllerDelegate?
    
    @IBOutlet weak var pageContainer: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var pageViewController: UIPageViewController!
    
    var currentIndex: Int? = 0
    fileprivate var pendingIndex: Int?
    
    var steps: [UIViewController]?
    
    var allowsGestures = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSteps()
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        
        if allowsGestures {
            pageViewController.dataSource = self
        }
        
        if let first = steps?.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
        
        pageContainer.addSubview(pageViewController.view)
        pageContainer.addConstraints(pageViewController.view.constraintsWithAttributes([.left, .right, .top, .bottom], .equal, to: pageContainer))
        
        pageControl.numberOfPages = steps?.count ?? 0
        pageControl.currentPage = 0
        pageControl.addTarget(self, action: #selector(pageControlOnValueChanged), for: .valueChanged)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        // Explicitly release the steps array so we don't keep the view controllers in memory
        if parent == nil {
            steps = nil
            delegate = nil
            pageViewController = nil
        }
    }
    
    func loadSteps() {
        steps = []
    }
    
    func loadPage(_ storyboard: String, _ vcIdentifier: String) -> UIViewController {
        return UIStoryboard(name: storyboard, bundle: nil).instantiateViewController(withIdentifier: vcIdentifier)
    }
    
    func goToLastPage() -> Bool {
        guard let last = steps?.last else {
            return false
        }
        
        pageViewController.setViewControllers([last], direction: .forward, animated: true) { (_) in
            guard let steps = self.steps else {
                return
            }
            
            self.pageControl.currentPage = steps.count - 1
            self.delegate?.pageChanged()
        }
        
        return true
    }
    
    @discardableResult
    func goToNextPage() -> Bool {
        guard let current = pageViewController.viewControllers?.first else {
            return false
        }
        
        guard let steps = steps else {
            return false
        }
        
        guard let index = steps.firstIndex(of: current) else {
            return false
        }
        
        guard index < steps.count - 1 else {
            return false
        }
        
        pageViewController.setViewControllers([steps[index + 1]], direction: .forward, animated: true) { (_) in
            self.pageControl.currentPage = index + 1
            self.currentIndex = index + 1
            self.delegate?.pageChanged()
        }
        
        return true
    }
    
    func goToPreviousPage() -> Bool {
        guard let current = pageViewController.viewControllers?.first else {
            return false
        }
        
        guard let steps = steps else {
            return false
        }
        
        guard let index = steps.firstIndex(of: current) else {
            return false
        }
        
        guard index > 0 else {
            return false
        }
        
        pageViewController.setViewControllers([steps[index - 1]], direction: .reverse, animated: true) { (_) in
            self.pageControl.currentPage = index - 1
            self.currentIndex = index - 1
            self.delegate?.pageChanged()
        }
        
        return true
    }
    
    @objc func pageControlOnValueChanged(_ sender: UIPageControl) {
        let direction: UIPageViewController.NavigationDirection = sender.currentPage > currentIndex! ? .forward : .reverse
        
        guard let steps = steps else {
            return
        }
        
        pageViewController.setViewControllers([steps[sender.currentPage]], direction: direction, animated: true) { (_) in
            self.currentIndex = sender.currentPage
            self.delegate?.pageChanged()
        }
    }
    
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        if direction == .left {
            return goToNextPage()
        } else if direction == .right {
            return goToPreviousPage()
        }
        
        return false
    }
}

extension CustomPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let steps = steps else {
            return nil
        }
        
        guard let currentIndex = steps.firstIndex(of: viewController) else {
            return nil
        }
        
        guard currentIndex > 0 else {
            return nil
        }
        
        let previousIndex = abs((currentIndex - 1) % steps.count)
        
        return steps[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let steps = steps else {
            return nil
        }
        
        guard let currentIndex = steps.firstIndex(of: viewController) else {
            return nil
        }
        
        guard currentIndex < steps.count - 1 else {
            return nil
        }
        
        let nextIndex = abs((currentIndex + 1) % steps.count)
        
        return steps[nextIndex]
    }
}

extension CustomPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let vc = pendingViewControllers.first else {
            return
        }
        
        pendingIndex = steps?.firstIndex(of: vc)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        
        currentIndex = pendingIndex
        
        if let index = currentIndex {
            pageControl.currentPage = index
            delegate?.pageChanged()
        }
    }
}
