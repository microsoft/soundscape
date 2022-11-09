//
//  NotificationObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol NotificationObserver: AnyObject {
    var delegate: NotificationObserverDelegate? { get set }
    var didDismiss: Bool { get }
    func notificationViewController(in viewController: UIViewController) -> UIViewController?
}

extension NotificationObserver {
    
    var manager: NotificationManager {
        return NotificationManager(self)
    }
    
}
