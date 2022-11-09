//
//  WaypointDetailClusterAnnotationView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

class WaypointDetailClusterAnnotationView: MKMarkerAnnotationView {
    
    static let identifier = "SoundscapeWaypointClusterAnnotationView"
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let newValue = newValue as? MKClusterAnnotation else {
                return
            }
            
            // Format color
            markerTintColor = Colors.Background.quaternary
            
            let waypointDetailAnnotations = newValue.memberAnnotations.compactMap({ return $0 as? WaypointDetailAnnotation })
            let sortedAnnotations = waypointDetailAnnotations.sorted(by: { return $0.detail.index < $1.detail.index })
            
            if let annotation = sortedAnnotations.first {
                // Format text
                glyphText = GDLocalizedString("waypoint_detail.annotation.cluster.title", annotation.detail.displayIndex)
            }
        }
    }
    
}
