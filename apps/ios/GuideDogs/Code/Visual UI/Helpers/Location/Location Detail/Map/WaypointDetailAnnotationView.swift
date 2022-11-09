//
//  WaypointDetailAnnotationView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

class WaypointDetailAnnotationView: MKMarkerAnnotationView {
    
    static let identifier = "SoundscapeWaypointAnnotationView"
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let newValue = newValue as? WaypointDetailAnnotation else {
                return
            }
            
            // Enable clustering
            clusteringIdentifier = "SoundscapeWaypointCluster"
            
            // Format color and text
            markerTintColor = Colors.Background.quaternary
            glyphText = newValue.detail.displayIndex
        }
    }
    
}
