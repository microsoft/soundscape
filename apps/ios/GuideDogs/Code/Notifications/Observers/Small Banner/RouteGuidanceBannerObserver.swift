//
//  RouteGuidanceBannerObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class RouteGuidanceBannerObserver: PersistentNotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    private var behavior: Behavior?
    
    // MARK: Initialization
    
    init() {
        self.behavior = AppContext.shared.eventProcessor.activeBehavior
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBehaviorDidActivate), name: Notification.Name.behaviorActivated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBehaviorDidDeactivate), name: Notification.Name.behaviorDeactivated, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onBehaviorDidActivate(_ notification: Notification) {
        guard let behavior = notification.userInfo?[EventProcessor.Keys.behavior] as? Behavior else {
            return
        }
        
        self.behavior = behavior
        
        delegate?.stateDidChange(self)
    }
    
    @objc
    private func onBehaviorDidDeactivate() {
        self.behavior = nil
        
        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationManager`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
}

extension RouteGuidanceBannerObserver: BannerViewControllerDelegate {
    
    func didSelect(_ bannerViewController: BannerViewController) {
        delegate?.performSegue(self, destination: AnyViewControllerRepresentable.routeGuidance)
    }
    
    func didDismiss(_ bannerViewController: BannerViewController) {
        // no-op
    }
    
}
