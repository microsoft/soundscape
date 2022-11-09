//
//  NotificationController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// The `NotificationController` listens for changes that might require we show a notification (e.g. a new page
/// is shown, Soundscape goes offline, a behavior is activated). When the controller detects a change
/// it requests notifications for the current view controller from the notification servers (`BannerServer` and `AlertServer`)
/// If the servers return a notification, then the controller requests that the current view controller display the
/// notification.
///
class NotificationController: NSObject {
    
    // MARK: Properties
    
    static let shared = NotificationController()
    
    private let alertContainerManager: NotificationContainerManager<AlertType>
    private let largeBannerContainerManager: NotificationContainerManager<LargeBanner>
    private let smallBannerContainerManager: NotificationContainerManager<SmallBanner>
    private let modalViewContainerManager: NotificationContainerManager<ModalView>
    
    // MARK: Initialization

    private override init() {
        self.alertContainerManager = NotificationContainerManager(AlertType.allCases)
        self.largeBannerContainerManager = NotificationContainerManager(LargeBanner.allCases)
        self.smallBannerContainerManager = NotificationContainerManager(SmallBanner.allCases)
        self.modalViewContainerManager = NotificationContainerManager(ModalView.allCases)
        
        super.init()
    }
    
}

extension NotificationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Notify controllers
        alertContainerManager.viewControllerWillChange(viewController)
        largeBannerContainerManager.viewControllerWillChange(viewController)
        smallBannerContainerManager.viewControllerWillChange(viewController)
        modalViewContainerManager.viewControllerWillChange(viewController)
    }
    
}
