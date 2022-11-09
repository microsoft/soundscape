//
//  CalloutWaypointDetailAnnotationView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

class CalloutWaypointDetailAnnotationView: MKMarkerAnnotationView {
    
    static let identifier = "SoundscapeCalloutWaypointAnnotationView"
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let newValue = newValue as? WaypointDetailAnnotation else {
                return
            }
            
            // Enable clustering
            clusteringIdentifier = "SoundscapeWaypointCluster"
            
            // Enable callout with detail disclosure
            canShowCallout = true
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            // Format color and text
            markerTintColor = Colors.Background.quaternary
            glyphText = newValue.detail.displayIndex
        }
    }
    
}
