//
//  AVAudio3DPoint+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation

extension AVAudio3DPoint {
    init(from bearing: CLLocationDirection, distance: CLLocationDistance = 1.0) {
        // Convert to radians and correct for the difference between the real world's coordinate system and the
        // virtual world's coordinate system.
        var radians = bearing.degreesToRadians - Double.pi / 2
        
        if radians < 0 {
            radians += 2 * Double.pi
        }
        
        self.init(x: Float(distance * cos(radians)), y: 0.0, z: Float(distance * sin(radians)))
    }
}
