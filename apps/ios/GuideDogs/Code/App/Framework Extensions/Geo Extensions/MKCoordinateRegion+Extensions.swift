//
//  MKCoordinateRegion+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

extension MKCoordinateRegion {

    /// The top-left coordinate of the region
    var northWest: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude  + (span.latitudeDelta  / 2.0),
                                      longitude: center.longitude - (span.longitudeDelta / 2.0))
    }
    
    /// The bottom-right coordinate of the region
    var southEast: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude  - (span.latitudeDelta  / 2.0),
                                      longitude: center.longitude + (span.longitudeDelta / 2.0))
    }
    
}

extension NSPredicate {
    
    /// A predicate for searching a specific coordinate region
    /// The `span` value indicate the amount of north-to-south and east-to-west distances (measured in meters) to use.
    convenience init(centerCoordinate: CLLocationCoordinate2D,
                     span: CLLocationDistance,
                     latitudeKey: String = "latitude",
                     longitudeKey: String = "longitude") {
        self.init(region: MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: span, longitudinalMeters: span),
                  latitudeKey: latitudeKey,
                  longitudeKey: longitudeKey)
    }
    
    convenience init(region: MKCoordinateRegion,
                     latitudeKey: String = "latitude",
                     longitudeKey: String = "longitude") {
        let format = "\(latitudeKey) < %f AND \(latitudeKey) > %f AND \(longitudeKey) > %f AND \(longitudeKey) < %f"
        let topLeft = region.northWest
        let bottomRight = region.southEast
        
        self.init(format: format,
            topLeft.latitude,
            bottomRight.latitude,
            topLeft.longitude,
            bottomRight.longitude)
    }

}
