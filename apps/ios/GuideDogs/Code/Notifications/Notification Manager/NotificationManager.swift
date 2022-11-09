//
//  NotificationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class NotificationManager {
    
    // MARK: Properties
    
    private let observer: NotificationObserver
    weak var delegate: NotificationManagerDelegate?
    
    // MARK: Initialization
    
    init(_ observer: NotificationObserver) {
        self.observer = observer
        self.observer.delegate = self
    }
    
    // MARK: `NotificationViewController`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard observer.didDismiss == false else {
            return nil
        }
        
        return observer.notificationViewController(in: viewController)
    }
    
}

extension NotificationManager: NotificationObserverDelegate {
    
    func stateDidChange(_ observer: NotificationObserver) {
        delegate?.stateDidChange(self)
    }
    
    func performSegue(_ observer: NotificationObserver, destination: ViewControllerRepresentable) {
        delegate?.performSegue(self, destination: destination)
    }
    
    func popToRootViewController(_ observer: NotificationObserver) {
        delegate?.popToRootViewController(self)
    }
    
}
