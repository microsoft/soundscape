//
//  NotificationServer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class NotificationServer<T: NotificationProtocol> {
    
    // MARK: Properties
    
    private let sortedNotificationManagers: [NotificationManager]
    weak var delegate: NotificationServerDelegate?
    
    // MARK: Initialization
    
    init(_ notifications: [T]) {
        self.sortedNotificationManagers = notifications.sorted(by: { (lhs, rhs) -> Bool in
            return lhs < rhs
        }).map({ NotificationManager($0.observer) })
        
        for manager in sortedNotificationManagers {
            manager.delegate = self
        }
    }
    
    // MARK: Notifications
    
    func requestNotification(in viewController: UIViewController) -> UIViewController? {
        for manager in sortedNotificationManagers {
            if let notificationViewController = manager.notificationViewController(in: viewController) {
                return notificationViewController
            }
        }
        
        return nil
    }
    
}

extension NotificationServer: NotificationManagerDelegate {
    
    func stateDidChange(_ manager: NotificationManager) {
        delegate?.stateDidChange(self)
    }
    
    func performSegue(_ manager: NotificationManager, destination: ViewControllerRepresentable) {
        delegate?.performSegue(self, destination: destination)
    }
    
    func popToRootViewController(_ manager: NotificationManager) {
        delegate?.popToRootViewController(self)
    }
    
}
