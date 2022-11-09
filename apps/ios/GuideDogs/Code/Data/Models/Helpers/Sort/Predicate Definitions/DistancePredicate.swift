//
//  DistanceSortPredicate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

struct DistancePredicate: SortPredicate {
    
    let origin: CLLocation
    let useEntranceIfAvailable: Bool
    
    init(origin: CLLocation, useEntranceIfAvailable: Bool = false) {
        self.origin = origin
        self.useEntranceIfAvailable = useEntranceIfAvailable
    }
    
    func areInIncreasingOrder(_ a: POI, _ b: POI) -> Bool {
        let aDistance = a.distanceToClosestLocation(from: origin, useEntranceIfAvailable: useEntranceIfAvailable)
        let bDistance = b.distanceToClosestLocation(from: origin, useEntranceIfAvailable: useEntranceIfAvailable)
        
        return aDistance < bDistance
    }
    
}
