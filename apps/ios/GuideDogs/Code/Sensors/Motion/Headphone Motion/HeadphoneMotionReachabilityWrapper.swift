//
//  HeadphoneMotionReachabilityWrapper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// `HeaphoneMotionManager` is only available iOS 14.4+
//
// This is a wrapper class which should be removed
// once support for iOS < 14.4 is removed
//
// This is a temporary class
class HeadphoneMotionManagerReachabilityWrapper {
    
    // MARK: Parameters
    
    let headphoneMotionManagerReachability: DeviceReachability?
    
    // MARK: Initialization
    
    init() {
        if #available(iOS 14.4, *) {
            headphoneMotionManagerReachability = HeadphoneMotionManagerReachability()
        } else {
            // `CMHeadphoneMotionManager` is not available on
            // iOS < 14.4
            headphoneMotionManagerReachability = nil
        }
    }
    
}

extension HeadphoneMotionManagerReachabilityWrapper: DeviceReachability {
    
    func ping(timeoutInterval: TimeInterval, completion: @escaping ReachabilityCompletion) {
        if let headphoneMotionManagerReachability = headphoneMotionManagerReachability {
            headphoneMotionManagerReachability.ping(timeoutInterval: timeoutInterval, completion: completion)
        } else {
            // `CMHeadphoneMotionManager` is not available on the device
            // e.g. Device is running iOS < 14.4
            completion(false)
        }
    }
    
}
