//
//  CallManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CallKit.CXCallObserver
import CocoaLumberjackSwift

enum CallStatusType: UInt {
    case began
    case ended
}

// MARK: Notifications

extension Notification.Name {
    static let callStatusChanged = Notification.Name("GDACallStatusChanged")
}

class CallManager: NSObject, CXCallObserverDelegate {
    
    // MARK: Keys
    
    struct Keys {
        static let callStatusTypeKey = "GDACallStatusTypeKey"
    }
    
    // MARK: Properties

    private let callObserver = CXCallObserver()
    private(set) var callInProgress = false

    /// When a call ends while the app is inactive, we notify that the call ended only after the app becomes active.
    private var shouldNotifyCallEndedWhenAppIsActive = false
    
    // MARK: Initialization

    override init() {
        super.init()
        callObserver.setDelegate(self, queue: nil)
    }
    
    // MARK: CXCallObserverDelegate
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        DDLogInfo("[Call] Call status changed: <isOutgoing: \(call.isOutgoing)> <hasConnected: \(call.hasConnected)> <hasEnded: \(call.hasEnded)> <isOnHold: \(call.isOnHold)>")
        
        if callInProgress && call.hasEnded {
            if AppContext.appState == .inactive {
                // "Call ended" will be handled when the app is active again
                shouldNotifyCallEndedWhenAppIsActive = true
                NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.appDidBecomeActive, object: nil)
            } else {
                handleCallEnded()
            }
        } else if !callInProgress {
            handleCallStarted()
        }
    }
    
    // MARK: Actions

    private func handleCallStarted() {
        DDLogInfo("[Call] Handling call started")
        
        callInProgress = true
        
        // The beacon audio will be handled in the `DestinationManager` class
        AppContext.shared.eventProcessor.hush(playSound: false, hushBeacon: false)
        
        NotificationCenter.default.post(name: .callStatusChanged,
                                        object: self,
                                        userInfo: [CallManager.Keys.callStatusTypeKey: CallStatusType.began.rawValue])
    }
    
    private func handleCallEnded() {
        DDLogInfo("[Call] Handling call ended")

        callInProgress = false
        
        if shouldNotifyCallEndedWhenAppIsActive {
            NotificationCenter.default.removeObserver(self, name: .callStatusChanged, object: nil)
            shouldNotifyCallEndedWhenAppIsActive = false
        }
        
        NotificationCenter.default.post(name: .callStatusChanged,
                                        object: self,
                                        userInfo: [CallManager.Keys.callStatusTypeKey: CallStatusType.ended.rawValue])
    }
    
    @objc private func appDidBecomeActive(_ notification: Notification) {
        guard shouldNotifyCallEndedWhenAppIsActive else {
            return
        }
        
        handleCallEnded()
    }
    
}
