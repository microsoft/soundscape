//
//  POI+Distance.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension POI {
    
    func distanceToClosestLocation(from location: CLLocation) -> CLLocationDistance {
        return distanceToClosestLocation(from: location, useEntranceIfAvailable: true)
    }
    
    func bearingToClosestLocation(from location: CLLocation) -> CLLocationDirection {
        return bearingToClosestLocation(from: location, useEntranceIfAvailable: true)
    }
    
    func closestLocation(from location: CLLocation) -> CLLocation {
        return closestLocation(from: location, useEntranceIfAvailable: true)
    }
    
}
