//
//  LocationDetailAnnotationView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

class LocationDetailAnnotationView: MKAnnotationView {
    
    static let identifier = "SoundscapeLocationAnnotationView"
    
    override var annotation: MKAnnotation? {
        willSet {
            // Use a custom image
            image = UIImage(named: "baseline_place_red_36pt")
        }
    }
    
}
