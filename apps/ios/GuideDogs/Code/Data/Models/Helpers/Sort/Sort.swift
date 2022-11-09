//
//  Sort.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

struct Sort {
    
    static func distance(origin: CLLocation, useEntranceIfAvailable: Bool = false) -> SortPredicate {
        return DistancePredicate(origin: origin, useEntranceIfAvailable: useEntranceIfAvailable)
    }
    
    static func lastSelected() -> SortPredicate {
        return LastSelectedPredicate()
    }
    
}
