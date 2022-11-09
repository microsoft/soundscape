//
//  OfflineBannerObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class OfflineBannerObserver: PersistentNotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    private var offlineState: OfflineState
    
    // MARK: Initialization
    
    init() {
        self.offlineState = AppContext.shared.offlineContext.state
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOfflineStateDidChange), name: Notification.Name.offlineStateDidChange, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onOfflineStateDidChange(_ notification: Notification) {
        guard let offlineState = notification.userInfo?[OfflineContext.Keys.state] as? OfflineState else {
            return
        }
        
        self.offlineState = offlineState
        
        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationManager`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard offlineState != .online else {
            return nil
        }
        
        var notificationViewController: BannerViewController?
        
        if offlineState == .offline {
            notificationViewController = OfflineBannerViewController(in: viewController)
        }
        
        if offlineState == .enteringOnline {
            notificationViewController = BannerViewController(nibName: "OnlineBanner")
        }
        
        // Initialize delegate
        notificationViewController?.delegate = self
        
        return notificationViewController
    }
    
}

extension OfflineBannerObserver: BannerViewControllerDelegate {
    
    func didSelect(_ bannerViewController: BannerViewController) {
        guard let offlineBannerViewController = bannerViewController as? OfflineBannerViewController else {
            return
        }
        
        guard let segue = offlineBannerViewController.segue else {
            return
        }
        
        delegate?.performSegue(self, destination: segue)
    }
    
    func didDismiss(_ bannerViewController: BannerViewController) {
        // no-op
    }
    
}
