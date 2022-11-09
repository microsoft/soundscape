//
//  UserActionManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Intents
import CocoaLumberjackSwift
import UIKit

extension Notification.Name {
    static let continueUserAction = Notification.Name("GDAContinueUserAction")
}

class UserActionManager {
    
    // MARK: Notification Keys
    
    struct Keys {
        static let userAction = "GDAUserAction"
    }
    
    // MARK: Static
    
    static var appUserActions: [NSUserActivity] {
        return UserAction.allCases.map { NSUserActivity(userAction: $0) }
    }
    
    static var appShortcuts: [INShortcut] {
        return appUserActions.map { INShortcut(userActivity: $0) }
    }
    
    // MARK: Properties
    
    private var pendingUserAction: UserAction?
    private var homeViewControllerDidLoad = false
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onHomeViewControllerDidLoad),
                                               name: Notification.Name.homeViewControllerDidLoad,
                                               object: nil)
        
        // Push notifications can contain a user action
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onPushNotificationReceived),
                                               name: Notification.Name.pushNotificationReceived,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onAppLocaleDidChange),
                                               name: .appLocaleDidChange,
                                               object: nil)
        
        if !FirstUseExperience.didComplete(.donateSiriShortcuts) {
            UserActionManager.donateSiriShortcuts()
            FirstUseExperience.setDidComplete(for: .donateSiriShortcuts)
        }
    }
    
    // MARK: Methods
    
    private static func donateSiriShortcuts() {
        let shortcuts = appShortcuts
        INVoiceShortcutCenter.shared.setShortcutSuggestions(shortcuts)
        GDLogAppInfo("Donated \(shortcuts.count) Siri shortcuts")
    }
    
    @discardableResult
    func continueUserAction(_ userAction: UserAction) -> Bool {
        guard homeViewControllerDidLoad else {
            GDLogAppInfo("Pending user action: \(userAction.rawValue)")
            pendingUserAction = userAction
            return true
        }
        
        if AppContext.shared.state != .normal {
            AppContext.shared.wakeUp()
        }
        
        GDATelemetry.track("user_activity.perform", value: userAction.rawValue)
        
        let postNotification = {
            // These actions will be handled by the home or the preview view controllers
            NotificationCenter.default.post(name: Notification.Name.continueUserAction,
                                            object: self,
                                            userInfo: [Keys.userAction: userAction])
        }
        
        switch userAction {
        case .myLocation, .aroundMe, .aheadOfMe, .nearbyMarkers:
            postNotification()
            return true
        case .search:
            if AppContext.shared.isStreetPreviewing {
                // Street Preview has it's own search flow
                postNotification()
                return true
            } else {
                return actionSearch()
            }
        case .saveMarker:
            return actionSaveMarker()
        case .streetPreview:
            return actionStreetPreview()
        }
    }
    
    private func continuePendingUserActionIfNeeded() {
        guard let pendingUserAction = pendingUserAction else { return }
        continueUserAction(pendingUserAction)
        self.pendingUserAction = nil
    }
    
    // MARK: Notifications
    
    @objc private func onHomeViewControllerDidLoad() {
        self.homeViewControllerDidLoad = true
        continuePendingUserActionIfNeeded()
    }
    
    @objc private func onPushNotificationReceived(_ notification: Notification) {
        guard let pushNotification = notification.userInfo?[PushNotificationManager.NotificationKeys.pushNotification] as? PushNotification,
              let userAction = pushNotification.userAction else { return }
        
        continueUserAction(userAction)
    }
    
    @objc private func onAppLocaleDidChange() {
        // Re-donate the Siri shortcuts to change the shortcuts locale.
        // If the Shortcuts app is open, it should be restarted.
        UserActionManager.donateSiriShortcuts()
    }
    
    // MARK: Actions
    
    private func actionSearch() -> Bool {
        guard !UserActionManager.isSearching else {
            return false
        }
        
        guard let rootViewController = rootViewController else { return false }
        guard let searchResultsTableViewController = SearchResultsTableViewController.instantiateStandaloneConfiguration() else { return false }
        rootViewController.present(searchResultsTableViewController, animated: true)
        
        return true
    }
    
    private func actionSaveMarker() -> Bool {
        guard let rootViewController = AppContext.rootViewController else { return false }
        
        guard let location = AppContext.shared.geolocationManager.location else {
            rootViewController.present(ErrorAlerts.buildLocationAlert(), animated: true, completion: nil)
            return false
        }
        
        let locationDetail = LocationDetail(location: location, telemetryContext: "current_location.user_activity.save")
        
        LocationDetail.fetchNameAndAddressIfNeeded(for: locationDetail) { (updatedLocationDetail) in
            let config = EditMarkerConfig(detail: updatedLocationDetail,
                                          context: "user_action",
                                          addOrUpdateAction: .dismissesViewController,
                                          deleteAction: .dismissesViewController,
                                          cancelAction: .dismissesViewController,
                                          leftBarButtonItemIsHidden: false)
            
            guard let vc = MarkerEditViewRepresentable(config: config).makeViewController() else { return }
            let nav = NavigationController(rootViewController: vc)
            nav.view.accessibilityIgnoresInvertColors = true
            rootViewController.present(nav, animated: true)
        }
        
        return true
    }
    
    private func actionStreetPreview() -> Bool {
        guard !AppContext.shared.isStreetPreviewing else {
            return false
        }
        
        guard !AppContext.shared.isRouteGuidanceActive else {
            return false
        }
        
        guard let rootViewController = AppContext.rootViewController else { return false }
        
        guard let location = AppContext.shared.geolocationManager.location else {
            rootViewController.present(ErrorAlerts.buildLocationAlert(), animated: true, completion: nil)
            return false
        }
        
        let storyboard = UIStoryboard(name: "Preview", bundle: nil)
        guard let nav = storyboard.instantiateInitialViewController() as? NavigationController,
              let vc = nav.topViewController as? PreviewViewController else { return false }
        
        nav.modalPresentationStyle = .fullScreen
        vc.locationDetail = LocationDetail(location: location, telemetryContext: "current_location.user_activity.street_preview")
        
        rootViewController.present(nav, animated: true)
        
        return true
    }
    
    // MARK: Helpers
    
    private var rootViewController: UIViewController? {
        guard let rootViewController = AppContext.rootViewController else { return nil }
        
        var visibleViewController = rootViewController.visiblePresentedViewController ?? rootViewController
        
        if visibleViewController is StandbyViewController {
            // If the app is in a sleep or snooze state, the `rootViewController` will be `StandbyViewController`.
            // We don't want to present views on top of it, but on its `presentingViewController`, which should be `HomeViewController`.
            visibleViewController = visibleViewController.presentingViewController ?? rootViewController
        }
        
        return visibleViewController
    }
    
    private static var isSearching: Bool {
        guard let rootViewController = AppContext.rootViewController?.visiblePresentedViewController as? UINavigationController else { return false }
        return rootViewController.topViewController is SearchResultsTableViewController
    }
    
}
