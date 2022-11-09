//
//  LocationDetailAnnotation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

class LocationDetailAnnotation: NSObject, MKAnnotation {
    
    // MARK: Paramters
    
    let detail: LocationDetail
    
    // `MKAnnotation` Parameters
    
    var coordinate: CLLocationCoordinate2D {
        return detail.centerLocation.coordinate
    }
    
    var title: String? {
        return detail.displayName
    }
    
    // MARK: Initialization
    
    init(detail: LocationDetail) {
        self.detail = detail
    }
    
}
