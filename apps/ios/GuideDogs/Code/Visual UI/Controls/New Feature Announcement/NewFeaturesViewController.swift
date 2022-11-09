//
//  NewFeaturesViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class NewFeaturesViewController: UIViewController {

    // This view controller can be populated with either one of these two
    var newFeatures: NewFeatures? // Will display only new features for this app version
    var features: [FeatureInfo]? // Will display all the features in the array
    
    @IBOutlet weak var cardView: BaseCardView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var countLabel: AdjustableLabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var footerView: UIView!
    
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.dataSource = self
        vc.delegate = self
        return vc
    }()
    
    var index = 0
    var featurePages: [FeaturePageViewController] = []
    var constraints: [NSLayoutConstraint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard newFeatures != nil || features != nil else {
            return
        }
        
        let featuresToDisplay = newFeatures != nil ? Array(newFeatures!.features.values.joined()) : features!
        let sorted = featuresToDisplay.sorted(by: { ($0.version < $1.version) || ($0.version == $1.version && $0.order < $1.order) })
        for feature in sorted {
            featurePages.append(FeaturePageViewController.create(feature: feature))
        }
        
        // Set up count and next button views
        countLabel.delegate = self
        refreshControls()
        
        // Setup the PageViewController
        pageViewController.setViewControllers([featurePages[index]], direction: .forward, animated: false, completion: nil)
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        
        constraints.append(pageViewController.view.leadingAnchor.constraint(equalTo: cardView.leadingAnchor))
        constraints.append(cardView.trailingAnchor.constraint(equalTo: pageViewController.view.trailingAnchor))
        constraints.append(pageViewController.view.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24.0))
        constraints.append(footerView.topAnchor.constraint(equalTo: pageViewController.view.bottomAnchor))
        
        NSLayoutConstraint.activate(constraints)
        
        pageViewController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("new_features")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: headerLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onDismissTouchUpInside(_ sender: UIButton) {
        guard index < featurePages.count - 1 else {
            topConstraint.constant = view.frame.height
            bottomConstraint.constant = -view.frame.height + 24
            
            UIView.animate(withDuration: 0.35, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (_) in
                self.dismiss(animated: true) {
                    self.newFeatures?.newFeaturesDidShow()
                }
            })
            
            return
        }
        
        index += 1
        
        changePage(to: index)
    }
    
    fileprivate func changePage(to index: Int, direction animationDirection: UIPageViewController.NavigationDirection = .forward, focusOnHeader: Bool = true) {
        let vc = featurePages[index]
        
        pageViewController.setViewControllers([vc], direction: animationDirection, animated: true, completion: { [weak self] (_) in
            if focusOnHeader {
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: vc.headerLabel)
            } else {
                let total = self?.featurePages.count ?? index + 1
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: "\(index + 1) of \(total). \(vc.header.accessibilityString()). \(vc.bodyAccessibilityLabel ?? "")")
            }
            
            self?.refreshControls()
        })
    }
    
    fileprivate func refreshControls() {
        let title: String
        var font = UIFont.preferredFont(forTextStyle: .body)
        
        if let buttonLabel = featurePages[index].buttonLabel {
            title = buttonLabel
        } else if index == featurePages.count - 1 {
            title = GDLocalizedString("general.alert.done")
            font = UIFont.systemFont(ofSize: font.pointSize, weight: .bold)
        } else {
            title = GDLocalizedString("general.alert.next")
        }
        
        let accessibilityHint: String
        
        if let buttonAccessibilityHint = featurePages[index].buttonAccessibilityHint {
            accessibilityHint = buttonAccessibilityHint
        } else {
            accessibilityHint = index == featurePages.count - 1 ? GDLocalizedString("settings.new_feature.accept_button.acc_label") : GDLocalizedString("settings.new_feature.accept_button.acc_hint")
        }
        
        countLabel.text = GDLocalizedString("settings.new_feature.num_of_num", String(index + 1), String(featurePages.count))
        acceptButton.setTitle(title, for: .normal)
        acceptButton.accessibilityLabel = title
        acceptButton.accessibilityHint = accessibilityHint
        acceptButton.titleLabel?.font = font
    }
}

extension NewFeaturesViewController: AdjustableLabelDelegate {
    func onAccessibilityIncrement() {
        guard index < featurePages.count - 1 else {
            return
        }
        
        index += 1
        
        changePage(to: index, focusOnHeader: false)
    }
    
    func onAccessibilityDecrement() {
        guard index > 0 else {
            return
        }
        
        index -= 1
        
        changePage(to: index, direction: .reverse, focusOnHeader: false)
    }
}

extension NewFeaturesViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let vc = pageViewController.viewControllers?.first as? FeaturePageViewController, let newIndex = featurePages.firstIndex(of: vc) else {
            return
        }
        
        self.index = newIndex
        refreshControls()
    }
}

extension NewFeaturesViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? FeaturePageViewController, let index = featurePages.firstIndex(of: vc), index < featurePages.count - 1 else {
            return nil
        }
        
        return featurePages[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? FeaturePageViewController, let index = featurePages.firstIndex(of: vc), index > 0 else {
            return nil
        }
        
        return featurePages[index - 1]
    }
}
