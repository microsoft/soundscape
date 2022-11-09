//
//  HeadphoneMotionManagerStatus.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum HeadphoneMotionStatus: Int {
    // `HeaphoneMotionManager` is not available on the device
    // e.g. Device is running iOS < 14.4
    case unavailable
    // Headphone motion has not been activated (enabled) by the user
    case inactive
    // Headphone motion is active, but headphones are not connected
    case disconnected
    // Headphone motion is active, and headphones are connected but not calibrated
    case connected
    // Headphone motion is active, and headphone are connected and calibrated
    case calibrated
}

extension HeadphoneMotionStatus: Equatable, Comparable {
    
    static func < (lhs: HeadphoneMotionStatus, rhs: HeadphoneMotionStatus) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
