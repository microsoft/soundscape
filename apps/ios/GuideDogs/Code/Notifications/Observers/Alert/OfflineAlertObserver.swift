//
//  OfflineAlertObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class OfflineAlertObserver: NotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    var didDismiss: Bool = false
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
        // Reset `didDismiss` state
        didDismiss = false

        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationObserver`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard offlineState == .offline else {
            return nil
        }
        
        let learnMoreHandler: (UIAlertAction) -> Void = { (_) in
            // Dismiss alert
            self.didDismiss = true
            
            // Segue to "Help" content
            self.delegate?.performSegue(self, destination: AnyViewControllerRepresentable.offlineHelp)
        }
        
        let dismissHandler: (UIAlertAction) -> Void = { (_) in
            // Dismiss alert
            self.didDismiss = true
        }
        
        if viewController is SearchTableViewController {
            return ErrorAlerts.buildOfflineSearchAlert(learnMoreHandler: learnMoreHandler, dismissHandler: dismissHandler)
        }
        
        if viewController is OfflineHelpPageViewController {
            return ErrorAlerts.buildOfflineHelpAlert(dismissHandler: dismissHandler)
        }
        
        return ErrorAlerts.buildOfflineDefaultAlert(learnMoreHandler: learnMoreHandler, dismissHandler: dismissHandler)
    }
    
}
