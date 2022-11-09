//
//  AppDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CocoaLumberjackSwift

// Uncomment for Siri use:
// import Intents.NSUserActivity_IntentsAdditions

extension Notification.Name {
    static let appWillEnterForeground = Notification.Name("GDAAppWillEnterForeground")
    static let appDidBecomeActive = Notification.Name("GDAAppDidBecomeActive")
    static let appDidEnterBackground = Notification.Name("GDAAppDidEnterBackground")
    static let didRegisterForRemoteNotifications = Notification.Name("GDADidRegisterForRemoteNotifications")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Properties

    var window: UIWindow?
    
    private let userActivityManager = UserActivityManager()
    private let urlResourceManager = URLResourceManager()
    let pushNotificationManager = PushNotificationManager(userId: SettingsContext.shared.clientId)
    
    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Check if we need to migrate Realm before we do anything else
        RealmMigrationTools.migrate(database: RealmHelper.databaseConfig, cache: RealmHelper.cacheConfig)
        
        if FirstUseExperience.didComplete(.oobe) {
            // Only increment app use count if the user has completed onboarding
            SettingsContext.shared.appUseCount += 1
        }
        
        // Note: Remainder of app initialization is handled in DynamicLaunchViewController.swift and LaunchHelper.swift...
        // DO NOT reference `AppContext.shared` until the notification `Notification.Name.appDidInitialize` is posted
        
        if let launchOptions = launchOptions {
            pushNotificationManager.didFinishLaunchingWithOptions(launchOptions)
        }
        
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return userActivityManager.onContinueUserActivity(userActivity)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let source = components.queryItems?.first(where: { $0.name == "source" })?.value {
            GDLogAppInfo("App opened from source: \(source)")
            GDATelemetry.track("app.open", with: ["source": source])
        }
        
        return urlResourceManager.onOpenResource(from: url)
    }
    
    // MARK: Application life cycle
    
    /// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    /// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    func applicationWillResignActive(_ application: UIApplication) {
        GDLogAppInfo("Application will resign active")
        
        AppContext.appState = .inactive
    }
    
    /// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    /// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    func applicationDidEnterBackground(_ application: UIApplication) {
        GDLogAppInfo("Application did enter background")
        
        AppContext.appState = .background
        
        NotificationCenter.default.post(name: Notification.Name.appDidEnterBackground, object: nil)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        GDLogAppInfo("Application will enter foreground")
        
        AppContext.appState = .inactive
        
        NotificationCenter.default.post(name: Notification.Name.appWillEnterForeground, object: nil)
    }
    
    /// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    func applicationDidBecomeActive(_ application: UIApplication) {
        GDLogAppInfo("Application did become active")
        
        AppContext.appState = .active
        AppContext.shared.validateActive()
        
        NotificationCenter.default.post(name: Notification.Name.appDidBecomeActive, object: nil)
    }
    
    /// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    func applicationWillTerminate(_ application: UIApplication) {
        GDLogAppInfo("Application will terminate")
        
        if AppContext.shared.geolocationManager.isTracking {
            AppContext.shared.geolocationManager.stopTrackingGPX()
        }
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        GDLogAppInfo("Application did receive memory warning")
        
        if let memoryAllocated = AppContext.memoryAllocated {
            GDLogAppInfo("Memory used: " + ByteCountFormatter.string(fromByteCount: Int64(memoryAllocated), countStyle: .memory))
        }
    }
    
}

// MARK: Push Notifications

extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        GDLogPushInfo("Did register for remote notifications")
        
        NotificationCenter.default.post(name: Notification.Name.didRegisterForRemoteNotifications, object: self)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        GDLogPushInfo("Did fail to register for remote notifications with error: \(error)")
    }
    
}
