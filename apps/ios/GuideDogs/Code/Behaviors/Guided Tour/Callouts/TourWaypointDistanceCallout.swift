//
//  TourWaypointDistanceCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class TourWaypointDistanceCallout: CalloutProtocol {
    let id = UUID()
    
    let origin: CalloutOrigin = .tourGuidance
    
    let timestamp = Date()
    
    let includeInHistory: Bool = false
    
    let includePrefixSound = true
    
    let index: Int
    
    let waypoint: LocationDetail
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "waypoint_distance"
    }
    
    var prefixSound: Sound? {
        return GlyphSound(.mobilitySense)
    }
    
    init(index: Int, waypoint: LocationDetail) {
        self.index = index
        self.waypoint = waypoint
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds {
        guard let location = location else {
            return Sounds.empty
        }
        
        let distance = location.distance(from: waypoint.location)
        
        let glyph = GlyphSound(.poiSense, at: waypoint.location)
        let distanceString = LanguageFormatter.formattedDistance(from: distance)
        let tts = TTSSound(GDLocalizedString("waypoint.callout", distanceString), at: waypoint.location)
        guard let layered = LayeredSound(glyph, tts) else {
            return Sounds(tts)
        }
        
        return Sounds(layered)
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool) -> String? {
        guard let location = location else {
            return nil
        }
        
        let distance = location.distance(from: waypoint.location)

        if tts {
            return LanguageFormatter.spellOutDistance(distance )
        }

        return LanguageFormatter.string(from: distance)
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        // This callout type doesn't have a matching card, so no more info description is needed
        return ""
    }
}
