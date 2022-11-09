//
//  MotionActivityUpdateFilter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// This class inherits the filtering capabilities of it's parent, and adds specific filtering logic for different user activities.
/// For example, we can configure different filtering options for walking or in-vehicle situations.
/// For additional information see: `LocationUpdateFilter`.
class MotionActivityUpdateFilter: LocationUpdateFilter {
    
    /// The motion activity that tracks the current user activity
    let motionActivity: MotionActivityProtocol
    
    /// We use this property multiplied with the `updateTimeInterval` to compute the in-vehicle time interval filter.
    var inVehicleTimeIntervalMultiplier: Double = 4

    init(minTime: TimeInterval, minDistance: CLLocationDistance, motionActivity: MotionActivityProtocol) {
        self.motionActivity = motionActivity
        
        super.init(minTime: minTime, minDistance: minDistance)
    }
    
    override func shouldUpdate(location: CLLocation) -> Bool {
        if motionActivity.isInVehicle {
            // Calculate the time interval filter
            // For example, if the update time interval is 5 seconds and the multiplier is 6,
            // the new time interval would be 30 seconds.
            let timeInterval = updateTimeInterval * inVehicleTimeIntervalMultiplier
            
            // Calculate the distance filter by using the distance, speed and time equation.
            // For example, if a user is traveling 20 mps (72 kmh) and the update time interval is 5 seconds
            // the new distance interval would be 100 meters.
            let distanceInterval = location.speed > 0 ? location.speed * updateTimeInterval : updateDistanceInterval
            
            return shouldUpdate(location: location, updateTimeInterval: timeInterval, updateDistanceInterval: distanceInterval)
        }
        
        return super.shouldUpdate(location: location)
    }
    
}
