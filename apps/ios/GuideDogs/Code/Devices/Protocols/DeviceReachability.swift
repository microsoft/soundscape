//
//  DeviceReachability.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol DeviceReachability {
    // Return `true` if device is reachable
    typealias ReachabilityCompletion = (Bool) -> Void
    
    func ping(timeoutInterval: TimeInterval, completion: @escaping ReachabilityCompletion)
}
