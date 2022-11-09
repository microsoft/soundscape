//
//  OfflineContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Notification.Name {
    static let offlineStateDidChange = Notification.Name("GDAOfflineStateDidChange")
}

///
/// Soundscape is offline when the device is not connected to the internet
/// (see `Reachability` code in `UIDeviceManager`) or when it fails to download
/// tile data from the Soundscape services (see `SpatialDataState` in `SpatialDataContext`).
///
/// This class tracks whether Soundscape is offline and notifies observers when a change in
/// state occurs.
///
class OfflineContext {
    
    struct Keys {
        static let state = "GDAOfflineStateKey"
    }
    
    // MARK: Properties
    
    // Duration that we should remain in `enteringOnline` state (seconds)
    private static let enteringOnlineDuration = TimeInterval(3.0)
    
    private var timer: Timer?
    
    private var isNetworkConnectionAvailable: Bool {
        didSet {
            guard oldValue != isNetworkConnectionAvailable else {
                return
            }
            
            if oldValue == false, isServicesAvailable == true {
                // Soundscape is no longer offline
                // `enteringOnline` state
                state = .enteringOnline
            } else if isNetworkConnectionAvailable == false {
                state = .offline
            }
        }
    }
    
    private var isServicesAvailable: Bool {
        didSet {
            guard oldValue != isServicesAvailable else {
                return
            }
            
            if oldValue == false, isNetworkConnectionAvailable == true {
                // Soundscape is no longer offline
                // `enteringOnline` state
                state = .enteringOnline
            } else if isServicesAvailable == false {
                state = .offline
            }
        }
    }
    
    private(set) var state = OfflineState.online {
        didSet {
            guard oldValue != state else {
                return
            }
            
            NotificationCenter.default.post(name: Notification.Name.offlineStateDidChange, object: nil, userInfo: [Keys.state: state])
            GDATelemetry.track("soundscape_offline", with: ["state": state.rawValue])
            
            if state == .enteringOnline {
                onEnteringOnlineState()
            }
            
            // Play the corresponding sound when we are transitioning
            // offline states
            if state == .offline {
                // Play "offline" sound
                AppContext.process(GlyphEvent(.offline))
            } else if state == .enteringOnline {
                // Play "online" sound
                AppContext.process(GlyphEvent(.online))
                // Include Voiceover annoucement
                UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("banner.online.message"))
            }
        }
    }
    
    // MARK: Initialization
    
    init(isNetworkConnectionAvailable: Bool, dataState: SpatialDataState) {
        self.isNetworkConnectionAvailable = isNetworkConnectionAvailable
        self.isServicesAvailable = dataState != .error
        
        if isNetworkConnectionAvailable == false || isServicesAvailable == false {
            state = .offline
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onNetworkConnectionDidChange), name: Notification.Name.networkConnectionChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onSpatialDataStateDidChange), name: Notification.Name.spatialDataStateChanged, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onNetworkConnectionDidChange(_ notification: Notification) {
        guard let isNetworkConnectionAvailable = notification.userInfo?[UIDeviceManager.Keys.isNetworkAvailable] as? Bool else {
            return
        }
        
        self.isNetworkConnectionAvailable = isNetworkConnectionAvailable
    }
    
    @objc
    private func onSpatialDataStateDidChange(_ notification: Notification) {
        guard let state = notification.userInfo?[SpatialDataContext.Keys.state] as? SpatialDataState else {
            return
        }
        
        if state == .error {
            // A service request failed
            // Soundscape services not available
            self.isServicesAvailable = false
        } else if self.isServicesAvailable == false, state == .ready {
            // After an `.error` state, services are not considered available
            // until the `.ready` state (e.g., ignore loading and waiting states that occur
            // as part of the service retry logic)
            self.isServicesAvailable = true
        }
    }
    
    // MARK: `enteringOnline`
    
    private func onEnteringOnlineState() {
        guard state == .enteringOnline else {
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: OfflineContext.enteringOnlineDuration, repeats: false, block: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard self.state == .enteringOnline else {
                // We are not in the expected state
                // State may have changed during duration of `timer`
                return
            }
            
            // Transition from `enteringOnline` to `online`
            self.state = .online
        })
    }
}
