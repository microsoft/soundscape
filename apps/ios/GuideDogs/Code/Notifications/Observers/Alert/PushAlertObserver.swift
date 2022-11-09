//
//  PushAlertObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SafariServices

class PushAlertObserver: NotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    var didDismiss: Bool = false
    private var pushNotification: PushNotification?
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.pushNotificationReceived),
                                               name: Notification.Name.pushNotificationReceived,
                                               object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func pushNotificationReceived(_ notification: Notification) {
        guard let pushNotification = notification.userInfo?[PushNotificationManager.NotificationKeys.pushNotification] as? PushNotification else {
            return
        }
        
        self.pushNotification = pushNotification
        
        didDismiss = false
        
        delegate?.stateDidChange(self)
    }
    
    private func didShowPush() {
        // Reset current push data
        didDismiss = true
        pushNotification = nil
    }
    
    // MARK: `NotificationObserver`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        guard let pushNotification = pushNotification else {
            return nil
        }
        
        var message: String? {
            if let subtitle = pushNotification.subtitle, let body = pushNotification.body {
                return subtitle + "\n" + body
            } else if let subtitle = pushNotification.subtitle {
                return subtitle
            } else if let body = pushNotification.body {
                return body
            } else {
                return nil
            }
        }
        
        guard pushNotification.title != nil || message != nil else {
            GDLogPushError("Cannot present push notification in-app alert. Reason: notification does not contain text.")
            return nil
        }
        
        let alertController = UIAlertController(title: pushNotification.title,
                                                message: message,
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: { [weak self] (_) in
            self?.didShowPush()
        })
        alertController.addAction(dismissAction)
        
        if let urlString = pushNotification.url,
            let url = URL(string: urlString),
            let rootViewController = AppContext.rootViewController {
            let openURLAction = UIAlertAction(title: GDLocalizedString("general.alert.open"), style: .default, handler: { [weak self] (_) in
                self?.didShowPush()

                let safariVC = SFSafariViewController(url: url)
                safariVC.preferredBarTintColor = Colors.Background.primary
                safariVC.preferredControlTintColor = Colors.Foreground.primary
                rootViewController.present(safariVC, animated: true, completion: nil)
            })
            alertController.addAction(openURLAction)
            alertController.preferredAction = openURLAction
        }
        
        return alertController
    }
    
}
