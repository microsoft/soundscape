//
//  KalmanFilter+CLLocation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension KalmanFilter {
    
    func process(location: CLLocation) -> CLLocation {
        let vector = [location.coordinate.latitude, location.coordinate.longitude]
        let timestamp = location.timestamp
        let accuracy = location.horizontalAccuracy
        
        guard let filteredVector = process(newVector: vector, newTimestamp: timestamp, newAccuracy: accuracy) else {
            return location
        }
        
        guard filteredVector.count == 2 else {
            return location
        }
        
        return CLLocation(coordinate: CLLocationCoordinate2DMake(filteredVector[0], filteredVector[1]),
                          altitude: location.altitude,
                          horizontalAccuracy: location.horizontalAccuracy,
                          verticalAccuracy: location.verticalAccuracy,
                          course: location.course,
                          speed: location.speed,
                          timestamp: location.timestamp)
    }
    
}
