//
//  MotionActivityProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol MotionActivityProtocol: AnyObject {
    // MARK: Properties
        
    var isWalking: Bool { get }
    var isInVehicle: Bool { get }
    var currentActivity: ActivityType { get }

    // MARK: Starting/Stopping Updates
    
    func startActivityUpdates()
    func stopActivityUpdates()
}
