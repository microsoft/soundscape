//
//  AnyModalViewObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Notification.Name {
    static let presentAnyModalViewController = Notification.Name("GDAPresentAnyModalViewController")
}

/*
 *
 * This class facilitates displaying modal views when working between UIKit and SwiftUI.
 * An example of when to use this class is when displaying a `UIActivityViewController` from a SwiftUI
 * view (`UIActivityViewController` is not currently supported in SwiftUI).
 *
 */
class AnyModalViewObserver: NotificationObserver {
    
    // MARK: Keys
    
    struct Keys {
        static let context = "Context"
    }
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    var didDismiss: Bool = false
    private var currentViewController: UIViewController?
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPresentAnyModalViewController(_:)), name: Notification.Name.presentAnyModalViewController, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onPresentAnyModalViewController(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        guard let context = userInfo[Keys.context] as? ViewControllerRepresentable else {
            return
        }
        
        guard let viewController = context.makeViewController() else {
            return
        }
        
        // Save context
        currentViewController = viewController
        
        // Notify delegate
        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationObserver`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard let activity = currentViewController else {
            return nil
        }
        
        // Reset `currentActivityContext`
        currentViewController = nil
        
        return activity
    }
    
}
