//
//  WaypointDetailAnnotation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

class WaypointDetailAnnotation: NSObject, MKAnnotation {
    
    // MARK: Parameters
    
    let detail: WaypointDetail
    let coordinate: CLLocationCoordinate2D
    let title: String?
    
    // MARK: Initialization
    
    init?(detail waypointDetail: WaypointDetail) {
        guard let locationDetail = waypointDetail.locationDetail else {
            return nil
        }
        
        self.detail = waypointDetail
        self.coordinate = locationDetail.location.coordinate
        self.title = locationDetail.displayName
    }
    
}
