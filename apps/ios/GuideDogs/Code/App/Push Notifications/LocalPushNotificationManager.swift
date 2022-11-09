//
//  LocalPushNotificationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import UserNotifications

/// Manages the scheduling of local push notifications
class LocalPushNotificationManager {
    
    private enum NotificationIdentifier: String, CaseIterable {
        case reminderHome = "GDAPushReminderHome"
        case reminderWalk = "GDAPushReminderWalk"
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var pendingNotificationRequests = [UNNotificationRequest]()
    
    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    // MARK: - Initialization
    
    init() {
        if !didSetBeacon {
            NotificationCenter.default.addObserver(self, selector: #selector(onBeaconStarted), name: .destinationChanged, object: nil)
        }
        
        if !didWalkWithApp {
            NotificationCenter.default.addObserver(self, selector: #selector(onMotionActivityDidChange(_:)), name: .motionActivityDidChange, object: nil)
        }
    }
    
    // MARK: - Actions
    
    /// Note: scheduling would only work in the user has granted notifications permissions
    func start() {
        refreshNotifications()
    }
    
    func refreshNotifications() {
        updatePendingNotifications { [weak self] in
            self?.pendingNotificationRequests.forEach({ pendingNotificationRequest in
                GDLogPushInfo("Pending local notification: \(pendingNotificationRequest.identifier)")
            })
            
            self?.unscheduleNotificationsIfNeeded()
            self?.scheduleNotificationsIfNeeded()
        }
    }
    
    private func updatePendingNotifications(completion: (() -> Void)? = nil) {
        notificationCenter.getPendingNotificationRequests { [weak self] notificationRequests in
            self?.pendingNotificationRequests = notificationRequests
            completion?()
        }
    }
    
    private func unscheduleNotificationsIfNeeded() {
        for localPushIdentifier in NotificationIdentifier.allCases where shouldUnschedule(localPushIdentifier) {
            unschedule(localPushIdentifier)
        }
    }
    
    private func scheduleNotificationsIfNeeded() {
        for localPushIdentifier in NotificationIdentifier.allCases where shouldSchedule(localPushIdentifier) {
            schedule(localPushIdentifier)
        }
    }
    
    private func schedule(_ localPushIdentifier: NotificationIdentifier) {
        let request = LocalPushNotificationManager.notificationRequest(for: localPushIdentifier)
        schedule(request)
        setScheduled(true, identifier: localPushIdentifier)
    }
    
    private func schedule(_ request: UNNotificationRequest) {
        notificationCenter.add(request) { (error) in
            if let error = error {
                GDLogPushError("Could not schedule local push notification. Error: \(error.localizedDescription)")
            } else {
                GDLogPushInfo("Scheduled local push notification for identifier: \(request.identifier)")
            }
            
            self.updatePendingNotifications()
        }
    }
    
    private func unschedule(_ localPushIdentifier: NotificationIdentifier) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [localPushIdentifier.rawValue])
        GDLogPushInfo("Unscheduled local push notification for identifier: \(localPushIdentifier.rawValue)")
        updatePendingNotifications()
    }
    
    func resetAll() {
        for localPushIdentifier in NotificationIdentifier.allCases {
            setScheduled(false, identifier: localPushIdentifier)
        }
    }
    
    // MARK: - User Defaults
    
    private func didSchedule(_ identifier: NotificationIdentifier) -> Bool {
        return userDefaults.bool(forKey: identifier.rawValue)
    }
    
    private func setScheduled(_ scheduled: Bool, identifier: NotificationIdentifier) {
        userDefaults.set(scheduled, forKey: identifier.rawValue)
    }
    
    // MARK: - Scheduling
    
    private func isPending(_ identifier: NotificationIdentifier) -> Bool {
        return pendingNotificationRequests.contains(where: { $0.identifier == identifier.rawValue })
    }
    
    private func shouldSchedule(_ identifier: NotificationIdentifier) -> Bool {
        switch identifier {
        case .reminderHome:
            return !didSchedule(.reminderHome) && !didSetBeacon
        case .reminderWalk:
            return !didSchedule(.reminderWalk) && !didWalkWithApp
        }
    }
    
    private func shouldUnschedule(_ identifier: NotificationIdentifier) -> Bool {
        switch identifier {
        case .reminderHome:
            return isPending(.reminderHome) && didSetBeacon
        case .reminderWalk:
            return isPending(.reminderWalk) && didWalkWithApp
        }
    }
    
    private static func notificationRequest(for identifier: NotificationIdentifier) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        let trigger: UNNotificationTrigger
        
        switch identifier {
        case .reminderHome:
            content.title = GDLocalizedString("push.local.home.title")
            content.body = GDLocalizedString("push.local.home.body")
            content.userInfo = [PushNotification.Keys.OriginContext: PushNotification.OriginContext.local.rawValue,
                                PushNotification.Keys.localIdentifier: NotificationIdentifier.reminderHome.rawValue]
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: DebugSettingsContext.shared.localPushNotification1TimeInternal, repeats: false)
        case .reminderWalk:
            content.title = GDLocalizedString("push.local.walk.title")
            content.body = GDLocalizedString("push.local.walk.body")
            content.userInfo = [PushNotification.Keys.OriginContext: PushNotification.OriginContext.local.rawValue,
                                PushNotification.Keys.localIdentifier: NotificationIdentifier.reminderWalk.rawValue]
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: DebugSettingsContext.shared.localPushNotification2TimeInternal, repeats: false)
        }
        
        let request = UNNotificationRequest(identifier: identifier.rawValue, content: content, trigger: trigger)
        return request
    }
    
}

// MARK: - Helpers

extension LocalPushNotificationManager {
    
    private var didSetBeacon: Bool {
        guard let beaconCountSet = GDATelemetry.helper?.beaconCountSet else { return false }
        return beaconCountSet > 0
    }
    
    private var didWalkWithApp: Bool {
        return GDATelemetry.helper?.didWalkWithApp ?? false
    }
    
}

// MARK: - Notification Handlers

extension LocalPushNotificationManager {
    
    @objc private func onBeaconStarted() {
        NotificationCenter.default.removeObserver(self, name: .destinationChanged, object: nil)
        refreshNotifications()
    }
    
    @objc private func onMotionActivityDidChange(_ notification: Notification) {
        guard let activityType = notification.userInfo?[MotionActivityContext.NotificationKeys.activityType] as? ActivityType,
              activityType == .walking else {
                  return
              }
        
        NotificationCenter.default.removeObserver(self, name: .motionActivityDidChange, object: nil)
        refreshNotifications()
    }
    
}
