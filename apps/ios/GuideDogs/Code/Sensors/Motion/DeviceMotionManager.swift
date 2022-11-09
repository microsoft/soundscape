//
//  MotionContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreMotion

extension Notification.Name {
    static let phoneIsFlatChanged = Notification.Name("GDAPhoneIsFlatChanged")
}

protocol DeviceMotionProvider: AnyObject {
    var isFlat: Bool { get }
}

class DeviceMotionManager: DeviceMotionProvider {
    
    // MARK: Notification Keys
    
    struct Keys {
        static let phoneIsFlat = "GDAPhoneIsFlatKey"
    }
    
    // MARK: Properties
    
    static let shared = DeviceMotionManager()
    
    private let motionManager = CMMotionManager()
    private(set) var isFlat = false
    
    // MARK: Actions
    
    func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            GDLogMotionVerbose("Could not start device motion updates. Device motion estimation is unavailable.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.5

        let operationQueue = OperationQueue()
        operationQueue.name = "DeviceMotionQueue"
        
        motionManager.startDeviceMotionUpdates(to: operationQueue) { (data, _) in
            guard let data = data else {
                // Failed to get data
                return
            }
            
            let roll = abs(data.attitude.roll)
            let pitch = abs(data.attitude.pitch)
            
            // Pitch and roll will be close to 0 when the
            // device is flat
            let newValue = roll < 0.5 && pitch < 0.5
            
            guard self.isFlat != newValue else {
                // Orientation has not changed
                return
            }
            
            self.isFlat = newValue
            
            // UI an Audio updates should be done on main thread
            OperationQueue.main.addOperation {
                // Notify the app that the isFlat value changed
                NotificationCenter.default.post(name: NSNotification.Name.phoneIsFlatChanged, object: self, userInfo: [DeviceMotionManager.Keys.phoneIsFlat: self.isFlat])
            }
        }
    }
    
    func stopDeviceMotionUpdates() {
        GDLogMotionVerbose("Stopping device motion updates")
        motionManager.stopDeviceMotionUpdates()
    }
}
