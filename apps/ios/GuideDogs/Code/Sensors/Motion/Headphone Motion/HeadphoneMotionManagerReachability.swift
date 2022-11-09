//
//  HeadphoneMotionManagerReachability.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreMotion

// `HeaphoneMotionManager` is not available on
// iOS < 14.4
@available(iOS 14.4, *)
// `NSObject` required for `CMHeadphoneMotionManagerDelegate`
class HeadphoneMotionManagerReachability: NSObject, DeviceReachability {
    
    // MARK: Properties
    
    private var motionManager: CMHeadphoneMotionManager?
    private var timer: Timer?
    private var completion: ReachabilityCompletion?
    private let lock = NSLock()
    private var isActive = false
    
    deinit {
        motionManager?.stopDeviceMotionUpdates()
    }
    
    // MARK: `DeviceReachability`
    
    func ping(timeoutInterval: TimeInterval, completion: @escaping ReachabilityCompletion) {
        guard isActive == false else {
            completion(false)
            return
        }
        
        // Update state
        isActive = true
        
        // Save completion handler
        self.completion = completion
        
        // Initialize `CMHeadphoneMotionManagerDelegate` for connecting and disconnecting
        // headphones
        let motionManager = CMHeadphoneMotionManager()
        
        // Save reference and set delegate
        self.motionManager = motionManager
        self.motionManager?.delegate = self
        
        guard motionManager.isDeviceMotionAvailable && CMHeadphoneMotionManager.authorizationStatus() == .authorized else {
            // `CMHeadphoneMotionManager` is not available on the device
            // e.g. Device is running iOS < 14.4
            //
            // Or `CMHeadphoneMotionManager` is not authorized
            //
            // Core Motion authorization is required for app use, so we can assume
            // that authorization status will always be `authorized`
            
            // Return result
            cleanup(isReachable: false)
            return
        }
        
        // `CMHeadphoneMotionManager` updates and timer need to run on
        // the main thread
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            GDLogHeadphoneMotionInfo("[PING] Starting headphone motion updates...")
            
            // Start updates
            self.motionManager?.startDeviceMotionUpdates()
            
            // Start timer
            self.timer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                GDLogHeadphoneMotionInfo("[PING] Scheduled timer did fire")
                
                // Timer fired before `headphoneMotionManagerDidConnect`
                self.cleanup(isReachable: false)
            }
        }
    }
    
    private func cleanup(isReachable: Bool) {
        self.lock.lock()
        
        defer {
            self.lock.unlock()
        }
        
        GDLogHeadphoneMotionInfo("[PING] Stopping headphone motion updates...")
        
        // Stop and reset timer
        timer?.invalidate()
        timer = nil
        
        // Stop and reset motion manager
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
        
        // Return reachability and reset
        completion?(isReachable)
        completion = nil
        
        // Update state
        isActive = false
    }
    
}

@available(iOS 14.4, *)
extension HeadphoneMotionManagerReachability: CMHeadphoneMotionManagerDelegate {
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        GDLogHeadphoneMotionInfo("[PING] Headphone Motion Manager did connect...")
        
        cleanup(isReachable: true)
    }
    
}
