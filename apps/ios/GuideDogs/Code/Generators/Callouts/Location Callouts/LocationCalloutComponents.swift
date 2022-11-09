//
//  LocationCalloutComponents.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

struct LocationCalloutComponents {
    let name: String
    let location: CLLocation
    let distance: CLLocationDistance
    let encodedDirection: String
    let bearing: CLLocationDirection
    
    var formattedDistance: String {
        return LanguageFormatter.string(from: distance, rounded: true)
    }
    
    init(name: String, location: CLLocation, distance: CLLocationDistance, encodedDirection: String, bearing: CLLocationDirection) {
        self.name = name
        self.location = location
        self.distance = distance
        self.encodedDirection = encodedDirection
        self.bearing = bearing
    }
}
