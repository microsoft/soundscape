//
//  BannerContainerManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// The `BannerContainerView` is an abstraction of `LargeBannerContainerView` and `SmallBannerContainerView`
/// and allows `BannerContainer` to present and dismiss a banner without needing to understand the underlying container view
/// implementation
///
class BannerContainerView {
    
    // MARK: Properties
    
    let containerViewController: UIViewController
    let containerView: UIView!
    let setContainerViewHeight: (CGFloat) -> Void
    
    // MARK: Initialization
    
    convenience init?(viewController: UIViewController, type: BannerContainer.BannerContainerType) {
        switch type {
        case .large:
            guard let container = viewController as? LargeBannerContainerView else {
                return nil
            }
            
            self.init(viewController: viewController, container: container)
        case .small:
            guard let container = viewController as? SmallBannerContainerView else {
                return nil
            }
            
            self.init(viewController: viewController, container: container)
        }
    }
    
    fileprivate convenience init(viewController: UIViewController, container: LargeBannerContainerView) {
        self.init(containerViewController: viewController, containerView: container.largeBannerContainerView, setContainerViewHeight: container.setLargeBannerHeight)
    }
    
    fileprivate convenience init(viewController: UIViewController, container: SmallBannerContainerView) {
        self.init(containerViewController: viewController, containerView: container.smallBannerContainerView, setContainerViewHeight: container.setSmallBannerHeight)
    }
    
    fileprivate init(containerViewController: UIViewController, containerView: UIView!, setContainerViewHeight: @escaping ((CGFloat) -> Void)) {
        self.containerViewController = containerViewController
        self.containerView = containerView
        self.setContainerViewHeight = setContainerViewHeight
    }
    
}
