//
//  DirectionRange.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// An interval from a direction lower bound up to, and including, an upper bound (measured in degrees).
/// - note: Values should be valid degrees between 0 and 360.
struct DirectionRange {
    
    let start: CLLocationDirection
    let end: CLLocationDirection
    
    init?(start: CLLocationDirection, end: CLLocationDirection) {
        guard start >= 0, start <= 360, end >= 0, end <= 360 else {
            return nil
        }
        
        self.start = start
        self.end = end
    }
    
    init?(direction: CLLocationDirection, windowRange: Double) {
        self.init(start: direction.add(degrees: -(windowRange/2)),
                  end: direction.add(degrees: windowRange/2))
    }
    
    /// Returns a value which indicates whether `direction` is contained within `start` and `end`.
    func contains(_ direction: CLLocationDirection) -> Bool {
        if end > start {
            return (direction >= start && direction <= end)
        } else {
            return (direction >= start || direction <= end)
        }
    }
    
}
