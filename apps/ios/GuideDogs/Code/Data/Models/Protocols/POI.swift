//
//  POI.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

/// Protocol for all OSM entity data structures
protocol POI {
    var key: String { get }
    
    var name: String { get }
    var localizedName: String { get }
    var superCategory: String { get }
    var addressLine: String? { get }
    var streetName: String? { get }
    var centroidLatitude: CLLocationDegrees { get }
    var centroidLongitude: CLLocationDegrees { get }
    
    func contains(location: CLLocationCoordinate2D) -> Bool
    func closestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocation
    func distanceToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDistance
    func bearingToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDirection
}

protocol SelectablePOI: POI {
    var lastSelectedDate: Date? { get set }
}

protocol MatchablePOI: POI {
    var matchKeys: [String] { get }
}

extension POI {
    
    var centroidCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: centroidLatitude, longitude: centroidLongitude)
    }
    
    var centroidLocation: CLLocation {
        return CLLocation(centroidCoordinate)
    }
    
}
