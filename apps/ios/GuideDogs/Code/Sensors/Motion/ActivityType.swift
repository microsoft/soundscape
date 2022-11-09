//
//  ActivityType.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreMotion

enum ActivityType: String {
    case stationary, walking, running, automotive, cycling, unknown
    
    init(motionActivity: CMMotionActivity) {
        // Because activities are not mutually exclusive, we check the automotive first.
        // For example, if the user was driving in a car and the car stopped at a red light,
        // the motion activity would have both the automotive and stationary properties set to true.
        if motionActivity.automotive {
            self = .automotive
        } else if motionActivity.walking {
            self = .walking
        } else if motionActivity.running {
            self = .running
        } else if motionActivity.cycling {
            self = .cycling
        } else if motionActivity.stationary {
            self = .stationary
        } else {
            self = .unknown
        }
    }
    
    var isInMotion: Bool {
        switch self {
        case .stationary:
            return false
        case .walking:
            return true
        case .running:
            return true
        case .automotive:
            return true
        case .cycling:
            return true
        case .unknown:
            return false
        }
    }
}

extension ActivityType: CustomStringConvertible {
    var description: String {
        return self.rawValue
    }
}
