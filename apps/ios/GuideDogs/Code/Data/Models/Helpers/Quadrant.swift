//
//  Quadrant.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct Quadrant {
    let left: CLLocationDirection
    let right: CLLocationDirection
    
    init(heading: CLLocationDirection) {
        left = (heading + 315).truncatingRemainder(dividingBy: 360.0)
        right = (heading + 45).truncatingRemainder(dividingBy: 360.0)
    }
    
    func contains(_ heading: CLLocationDirection) -> Bool {
        let wrappedHeading = heading.truncatingRemainder(dividingBy: 360.0)
        
        if wrappedHeading >= left && wrappedHeading < right {
            return true
        } else if right < left && (wrappedHeading >= left || wrappedHeading < right) {
            return true
        }
        
        return false
    }
}
