//
//  LocationPredicate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

struct LocationPredicate: FilterPredicate {
    
    let expectedLocation: CLLocation
    
    init(expected: CLLocation) {
        self.expectedLocation = expected
    }
    
    func isIncluded(_ a: POI) -> Bool {
        return a.contains(location: expectedLocation.coordinate)
    }
    
}
