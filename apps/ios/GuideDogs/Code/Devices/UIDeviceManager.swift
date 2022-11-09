//
//  UIDeviceManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  Description:
//
//  This class represents the device that the app is running on. It is where you can find out things like the
//  battery level, network status, and so on.
//

import UIKit
import Reachability
import CocoaLumberjackSwift

extension Notification.Name {
    static let networkConnectionChanged = Notification.Name("GDANetworkConnectionChanged")
    static let uiDeviceStateDidChange = Notification.Name("GDADeviceStateDidChange")
}

class UIDeviceManager: NSObject {
    
    struct Keys {
        static let isNetworkAvailable = "GDAIsNetworkAvailableKey"
        static let state = "GDADeviceState"
    }
    
    // MARK: Enums
    
    enum Orientation {
        case horizontal
        case unknown
    }
    
    enum State: String {
        case `default`
        case unknown
    }

    // MARK: Properties
    
    // Reachability Properties
    
    private let reachability = try? Reachability()

    var isNetworkConnectionAvailable: Bool {
        guard let reachability = reachability else { return false }
        return reachability.connection != .unavailable
    }
    
    var isReachableViaWiFi: Bool {
        guard let reachability = reachability else { return false }
        return reachability.connection == .wifi
    }
    
    // Device State Properties
    
    private var applicationStateIsActive: Bool = true {
        didSet {
            guard oldValue != applicationStateIsActive else {
                return
            }
            
            if applicationStateIsActive {
                state = .default
            } else if orientation == .unknown {
                state = .unknown
            }
        }
    }
    
    private var orientation: Orientation = .unknown {
        didSet {
            guard oldValue != orientation else {
                return
            }
            
            if orientation == .horizontal {
                state = .default
            } else if applicationStateIsActive == false {
                state = .unknown
            }
        }
    }
    
    var state: State = .default {
        didSet {
            guard oldValue != state else {
                return
            }
            
            GDLogAppInfo("Device state: \(state.rawValue)")
            
            let userInfo = [Keys.state: state]
            NotificationCenter.default.post(name: Notification.Name.uiDeviceStateDidChange, object: self, userInfo: userInfo)
        }
    }
    
    // Static Properties
    
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    private static var batteryState: UIDevice.BatteryState {
        return UIDevice.current.batteryState
    }
    
    private static var batteryLevel: Float {
        return UIDevice.current.batteryLevel
    }
    
    // MARK: - Initialization

    override init() {
        super.init()

        // Battery configutation
        
        UIDevice.current.isBatteryMonitoringEnabled = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.batteryStateChanged),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.batteryLevelChanged),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        
        // Notify of current battery status
        NotificationCenter.default.post(name: UIDevice.batteryStateDidChangeNotification, object: self)
        NotificationCenter.default.post(name: UIDevice.batteryLevelDidChangeNotification, object: self)
        
        // Network configutation

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reachabilityStateChanged),
                                               name: Notification.Name.reachabilityChanged,
                                               object: reachability)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAppWillEnterForeground), name: Notification.Name.appWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAppDidEnterBackground), name: Notification.Name.appDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDeviceOrientationDidChange(notification:)), name: Notification.Name.phoneIsFlatChanged, object: nil)
        
        do {
            try reachability?.startNotifier()
        } catch {
            DDLogWarn("Could not start reachability notifier")
        }
    }
    
    deinit {
        reachability?.stopNotifier()
    }
    
    // MARK: Notifications

    @objc private func batteryStateChanged(_ notification: NSNotification) {
        if UIDeviceManager.isSimulator {
            GDLogBatteryInfo("Battery state: Simulator")
        } else {
            GDLogBatteryInfo("Battery state: \(UIDeviceManager.batteryState.description)")
        }
    }
    
    @objc private func batteryLevelChanged(_ notification: NSNotification) {
        if UIDeviceManager.isSimulator {
            GDLogBatteryInfo("Battery level: Simulator")
        } else if UIDeviceManager.batteryLevel < 0 {
            GDLogBatteryInfo("Battery level: Unknown")
        } else {
            GDLogBatteryInfo("Battery level: " + String(format: "%.0f", UIDeviceManager.batteryLevel*100) + "%")
        }
    }
    
    @objc private func reachabilityStateChanged(_ notification: NSNotification) {
        let reachability = notification.object as! Reachability
        
        if reachability.connection != .unavailable {
            if reachability.connection == .wifi {
                GDLogNetworkWarn("Network status: WiFi connection")
            } else {
                GDLogNetworkWarn("Network status: Cellular connection")
            }
        } else {
            GDLogNetworkWarn("Network status: Offline")
        }
        
        NotificationCenter.default.post(name: Notification.Name.networkConnectionChanged, object: nil, userInfo: [Keys.isNetworkAvailable: isNetworkConnectionAvailable])
    }
    
    @objc
    private func onAppWillEnterForeground() {
        applicationStateIsActive = true
    }
    
    @objc
    private func onAppDidEnterBackground() {
        applicationStateIsActive = false
    }
    
    @objc
    private func onDeviceOrientationDidChange(notification: Notification) {
        guard let isFlat = notification.userInfo?[DeviceMotionManager.Keys.phoneIsFlat] as? Bool else {
            return
        }
        
        if isFlat {
            orientation = .horizontal
        } else {
            orientation = .unknown
        }
    }
    
}
