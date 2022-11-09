//
//  SoundType.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

enum SoundDistanceRenderingStyle: String {
    /// Sound is mapped onto a ring at head height surrounding the user
    case ring
    
    /// Sound is placed at its actual location in the virtual world
    case real
}

extension SoundDistanceRenderingStyle {
    var formattedLog: String {
        switch self {
        case .ring:
            return "ring \(DebugSettingsContext.shared.envRenderingDistance.roundToDecimalPlaces(1))m"
        default:
            return rawValue
        }
    }
}

/// Specifies the rendering style for a sound
enum SoundType {
    
    /// Standard 2D audio
    case standard
    
    /// 3D audio localized to a GPS coordinate (e.g. a POI callout with a specific location in the world)
    case localized(CLLocation, SoundDistanceRenderingStyle)
    
    /// 3D audio relative to the user's heading (e.g. a callout that is always to the user's right regardless of where they are looking)
    case relative(CLLocationDirection, SoundDistanceRenderingStyle)
    
    /// 3D audio localized to a compass direction (e.g. audio that always comes from north of the user)
    case compass(CLLocationDirection, SoundDistanceRenderingStyle)
    
}
