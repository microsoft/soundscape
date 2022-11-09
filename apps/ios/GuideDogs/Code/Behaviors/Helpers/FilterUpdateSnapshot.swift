//
//  FilterUpdateSnapshot.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct FilterUpdateSnapshot {
    /// Time of the update
    let time: Date
    
    /// Location of the update
    let location: CLLocation
    
    /// Time elapsed between this update and the previous update (maintained for logging purposes)
    let elapsed: TimeInterval
    
    /// Distance between the location of this update and the previous update (maintained for logging purposes)
    let distance: CLLocationDistance
    
    init(_ location: CLLocation, elapsed: TimeInterval = 0.0, distance: CLLocationDistance = 0.0) {
        self.time = Date()
        self.location = location
        self.elapsed = elapsed
        self.distance = distance
    }
}
