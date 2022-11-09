//
//  BannerContainer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// The `BannerContainer` is responsible for presenting and dismissing a banner in any view controller
/// that conforms to `LargeBannerContainerView` or `SmallBannerContainerView` and can be used
/// to create the abstracting `BannerContainerView` object.
///
class BannerContainer: NotificationContainer {
    
    enum BannerContainerType {
        case large
        case small
    }
    
    // MARK: Properties
    
    private static let animationDuration: TimeInterval = 0.10
    private static let maxContentHeight: CGFloat = 90.0
    
    private let bannerContainerType: BannerContainerType
    private var bannerViewController: BannerViewController?
    private var bannerContainer: BannerContainerView?
    
    // MARK: Initialization
    
    init(type: BannerContainerType) {
        self.bannerContainerType = type
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    // MARK: `UIContentSizeCategory`
    
    @objc
    private func contentSizeCategoryDidChange() {
        guard let bannerViewController = bannerViewController else {
            return
        }
        
        guard let bannerContainer = bannerContainer else {
            return
        }
        
        setContainerViewHeightForContentSize(content: bannerViewController, container: bannerContainer)
    }
    
    private func setContainerViewHeightForContentSize(content bannerViewController: BannerViewController, container bannerContainer: BannerContainerView) {
        // Calculated preferred height for `bannerViewController`
        let preferredContentHeight = UIView.preferredContentHeight(for: bannerViewController.contentView)
        
        let bannerHeight = min(BannerContainer.maxContentHeight, preferredContentHeight)
        
        bannerContainer.setContainerViewHeight(bannerHeight)
    }
    
    // MARK: `NotificationContainer`
    
    func present(_ viewController: UIViewController, presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let bannerViewController = viewController as? BannerViewController else {
            completion?()
            return
        }
        
        guard let bannerContainer = BannerContainerView(viewController: presentingViewController, type: bannerContainerType) else {
            completion?()
            return
        }
        
        // Add `UIViewController` and `UIView`
        bannerContainer.containerViewController.add(bannerViewController)
        bannerContainer.containerView.addSubview(bannerViewController.view)
        
        // Update height of container
        if animated {
            UIView.animate(withDuration: BannerContainer.animationDuration) {
                self.setContainerViewHeightForContentSize(content: bannerViewController, container: bannerContainer)
            }
        } else {
            self.setContainerViewHeightForContentSize(content: bannerViewController, container: bannerContainer)
        }
        
        // Set layout for `child.view`
        bannerViewController.view.frame = bannerContainer.containerView.bounds
        bannerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Ready to display
        bannerViewController.didMove(toParent: bannerContainer.containerViewController)
        
        bannerContainer.containerViewController.view.layoutSubviews()
        
        // Save banner view controller and container
        self.bannerViewController = bannerViewController
        self.bannerContainer = bannerContainer
        
        // Ensures that Voiceover is aware of new layout
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
        
        completion?()
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let bannerViewController = bannerViewController else {
            completion?()
            return
        }
        
        guard let bannerContainer = bannerContainer else {
            completion?()
            return
        }
        
        // Update height of container
        if animated {
            UIView.animate(withDuration: BannerContainer.animationDuration) {
                bannerContainer.setContainerViewHeight(0.0)
            }
        } else {
            bannerContainer.setContainerViewHeight(0.0)
        }
        
        // Remove view controller and view
        bannerViewController.remove()
        
        self.bannerViewController = nil
        self.bannerContainer = nil
        
        // Ensures that Voiceover is aware of new layout
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
        
        completion?()
    }
    
}
