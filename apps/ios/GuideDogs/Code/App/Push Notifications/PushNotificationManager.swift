//
//  PushNotificationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine
import WindowsAzureMessaging

extension Notification.Name {
    static let pushNotificationReceived = Notification.Name("GDAPushNotificationReceived")
}

/// A class to handle actions related to remote push notifications
class PushNotificationManager: NSObject {
    
    // MARK: Constants
    
    struct NotificationKeys {
        static let pushNotification = "GDAPushNotification"
    }
    
    private struct InfoPlistKeys {
        struct AzureNHConnectionString {
            static let `default` = "SOUNDSCAPE_AZURE_NH_CONNECTION_STRING"
            static let dogfood = "SOUNDSCAPE_AZURE_DF_NH_CONNECTION_STRING"
        }
        struct AzureNHPath {
            static let `default` = "SOUNDSCAPE_AZURE_NH_PATH"
            static let dogfood = "SOUNDSCAPE_AZURE_DF_NH_PATH"
        }
    }
    
    private static var globalTags: [String: String] {
        let tags = [
            "device.model": UIDevice.current.modelName,
            "device.os.version": UIDevice.current.systemVersion,
            "device.voice_over": UIAccessibility.isVoiceOverRunning ? "on" : "off",
            
            "app.version": AppContext.appVersion,
            "app.build": AppContext.appBuild,
            "app.source": BuildSettings.source.rawValue,
            
            "app.language": LocalizationContext.currentLanguageCode,
            "app.region": LocalizationContext.currentRegionCode
        ].mapValues { $0.lowercased().replace(characterSet: .whitespacesAndNewlines, with: "-") }
        
        return tags
    }
    
    // MARK: - Properties
    
    private static var azureConnectionString: String? {
        let key = BuildSettings.source == .appCenter ?
            InfoPlistKeys.AzureNHConnectionString.dogfood :
            InfoPlistKeys.AzureNHConnectionString.default
        
        guard let azureConnectionString = Bundle.main.infoPlistValue(forKey: key) else {
            GDLogPushError("Error: The Azure connection string was not found in the Info.plist file. Please set a valid value for key '\(key)'")
            return nil
        }
        
        return azureConnectionString
    }
    private static var azureNotificationHubPath: String? {
        let key = BuildSettings.source == .appCenter ?
            InfoPlistKeys.AzureNHPath.dogfood :
            InfoPlistKeys.AzureNHPath.default
        
        guard let azureNotificationHubPath = Bundle.main.infoPlistValue(forKey: key) else {
            GDLogPushError("Error: The Azure notification hub path was not found in the Info.plist file. Please set a valid value for key '\(key)'")
            return nil
        }
        
        return azureNotificationHubPath
    }
    
    // MARK: - Properties
    
    private var userId: String?
    private var subscribers: [AnyCancellable] = []
    
    private var onboardingDidComplete = false
    private var appDidInitialize = false
    private var pendingPushNotification: PushNotification?
    
    private(set) var localPushNotificationManager = LocalPushNotificationManager()
    
    private var notificationPresentationCompletion: ((UNNotificationPresentationOptions) -> Void)?
    private var notificationResponseCompletion: (() -> Void)?
    
    // MARK: - Initialization
    
    init(userId: String? = nil) {
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
        
        MSNotificationHub.setDelegate(self)
        MSNotificationHub.setLifecycleDelegate(self)
        MSNotificationHub.setEnrichmentDelegate(self)
        
        self.userId = userId
        self.onboardingDidComplete = FirstUseExperience.didComplete(.oobe)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAppDidInitialize),
                                               name: NSNotification.Name.appDidInitialize,
                                               object: nil)
        
        if onboardingDidComplete == false {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onOnboardingDidComplete),
                                                   name: .onboardingDidComplete,
                                                   object: nil)
        }
        
        subscribers.append(NotificationCenter.default
                            .publisher(for: .didRegisterForRemoteNotifications)
                            .receive(on: RunLoop.main)
                            .sink { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            if let userId = self.userId {
                self.updateUserIdIfNeeded(userId: userId)
            }
            
            self.updateTagsIfNeeded()
        })
    }
    
    deinit {
        subscribers.forEach({ $0.cancel() })
        subscribers.removeAll()
    }
    
    // MARK: Class Methods
    
    /// Initializes the Azure Notification Hub
    func start() {
        guard onboardingDidComplete else {
            // Do not start until the OOBE completes
            // Once the notification hub is started, the user will be asked
            // to approve notification permissions
            return
        }
        
        guard let connectionString = PushNotificationManager.azureConnectionString,
              let hubName = PushNotificationManager.azureNotificationHubPath else {
                  GDLogPushError("Error: The Azure notification hub connection string or hub name was not found in the Info.plist file")
                  return
              }
        
        MSNotificationHub.start(connectionString: connectionString, hubName: hubName)
    }
    
    private func updateUserIdIfNeeded(userId: String) {
        guard userId != MSNotificationHub.getUserId() else {
            return
        }
        
        MSNotificationHub.setUserId(userId)
    }
    
    /// Compares the global tags to the `MSNotificationHub` tags and updates values as needed
    private func updateTagsIfNeeded() {
        let globalTags = PushNotificationManager.globalTags
        let currentTags = MSNotificationHub.getTags()
        
        var tagsToRemove: [String] = []
        var tagsToAdd: [String] = []
        
        for (globalTagKey, globalTagValue) in globalTags {
            let globalTag = "\(globalTagKey):\(globalTagValue)"
            
            guard let currentTag = currentTags.first(where: { $0.hasPrefix(globalTagKey) }) else {
                // Global tag does not exists in notification hub tags, add it.
                tagsToAdd.append(globalTag)
                continue
            }
            
            let parts = currentTag.split(separator: ":")
            guard parts.count == 2 else {
                // Valid global tag should have the format "key:value"
                continue
            }
            
            let currentTagValue = String(parts[1])
            
            if currentTagValue != globalTagValue {
                // Global tag has changed, clear old value and update new one.
                // For example, iOS has been updated: "device.os.version:14.0" -> "device.os.version:14.1"
                tagsToRemove.append(currentTag)
                tagsToAdd.append(globalTag)
            }
        }
        
        if !tagsToRemove.isEmpty {
            GDLogPushInfo("Removing tags: \(tagsToRemove)")
            MSNotificationHub.removeTags(tagsToRemove)
        }
        
        if !tagsToAdd.isEmpty {
            GDLogPushInfo("Adding tags: \(tagsToAdd)")
            MSNotificationHub.addTags(tagsToAdd)
        }
    }
    
    func didFinishLaunchingWithOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]) {
        guard let remoteNotification = launchOptions[.remoteNotification] as? PushNotification.Payload else { return }
        let pushNotification = PushNotification(payload: remoteNotification, arrivalContext: .launch)
        didReceive(pushNotification: pushNotification)
    }
    
    // MARK: Receiving Push Notifications
    
    func didReceive(pushNotification: PushNotification) {
        guard appDidInitialize else {
            pendingPushNotification = pushNotification
            GDLogPushInfo("Did receive pending push notification")
            return
        }
        
        GDLogPushInfo(String(format: "Did receive push notification. App state: %@, Origin context: %@, Arrival context: %@, Payload: %@",
                      UIApplication.shared.applicationState.description,
                      pushNotification.originContext.rawValue,
                      pushNotification.arrivalContext.rawValue,
                      pushNotification.payload))
        
        GDATelemetry.track("push.received_notification", with: [
            "origin_context": pushNotification.originContext.rawValue,
            "arrival_context": pushNotification.arrivalContext.rawValue,
            "local_identifier": pushNotification.localIdentifier ?? "none"
        ])
        
        NotificationCenter.default.post(name: Notification.Name.pushNotificationReceived,
                                        object: nil,
                                        userInfo: [NotificationKeys.pushNotification: pushNotification])
    }
    
    // MARK: Notifications
    
    @objc private func onOnboardingDidComplete() {
        onboardingDidComplete = true
        NotificationCenter.default.removeObserver(self, name: .onboardingDidComplete, object: nil)
        
        start()
        
        if appDidInitialize, let pendingPushNotification = pendingPushNotification {
            didReceive(pushNotification: pendingPushNotification)
            self.pendingPushNotification = nil
        }
    }
    
    @objc private func onAppDidInitialize() {
        appDidInitialize = true
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.appDidInitialize, object: nil)
        
        if onboardingDidComplete, let pendingPushNotification = pendingPushNotification {
            didReceive(pushNotification: pendingPushNotification)
            self.pendingPushNotification = nil
        }
    }
    
}

// MARK: - MSNotificationHubDelegate

extension PushNotificationManager: MSNotificationHubDelegate {
    
    func notificationHub(_ notificationHub: MSNotificationHub, didRequestAuthorization granted: Bool, error: Error?) {
        if let error = error {
            GDLogPushError("Error requesting authorization for push notifications: \(error.localizedDescription)")
        } else {
            GDLogPushInfo("Push notifications authorization \(granted ? "granted" : "denied")")
        }
        
        GDATelemetry.track("push.request_authorization", with: ["granted": granted.description,
                                                                "error": error?.localizedDescription ?? "none"])
        
        localPushNotificationManager.start()
    }
    
    func notificationHub(_ notificationHub: MSNotificationHub, didReceivePushNotification message: MSNotificationHubMessage) {
        defer {
            if let notificationPresentationCompletion = notificationPresentationCompletion {
                notificationPresentationCompletion([])
                self.notificationPresentationCompletion = nil
            }
            
            if let notificationResponseCompletion = notificationResponseCompletion {
                notificationResponseCompletion()
                self.notificationResponseCompletion = nil
            }
        }
        
        guard let userInfo = message.userInfo else { return }
        let pushNotification = PushNotification(payload: userInfo)
        
        didReceive(pushNotification: pushNotification)
    }
    
}

// MARK: - MSInstallationLifecycleDelegate

extension PushNotificationManager: MSInstallationLifecycleDelegate {
    
    func notificationHub(_ notificationHub: MSNotificationHub!, didSave installation: MSInstallation!) {
        GDLogPushInfo("Successfully saved installation with ID: \(installation.installationId ?? "none")")
    }
    
    func notificationHub(_ notificationHub: MSNotificationHub!, didFailToSave installation: MSInstallation!, withError error: Error!) {
        GDLogPushError("Failed to save installation with ID: \(installation.installationId ?? "none") error: \(error?.localizedDescription ?? "none")")
    }
    
}

// MARK: - MSInstallationEnrichmentDelegate

extension PushNotificationManager: MSInstallationEnrichmentDelegate {
    
    func notificationHub(_ notificationHub: MSNotificationHub!, willEnrichInstallation installation: MSInstallation!) {
        GDLogPushInfo("Will enrich installation with ID: \(installation.installationId ?? "none")")
    }
    
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        notificationPresentationCompletion = completionHandler
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        notificationResponseCompletion = completionHandler
    }
    
}

// MARK: -

private extension Bundle {
    
    func infoPlistValue(forKey key: String) -> String? {
        guard let value = self.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else { return nil }
        return value
    }
    
}
