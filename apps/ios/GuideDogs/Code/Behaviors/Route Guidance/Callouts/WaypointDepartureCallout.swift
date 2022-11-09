//
//  WaypointDepartureCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

class WaypointDepartureCallout: CalloutProtocol {
    let id = UUID()
    let origin: CalloutOrigin = .routeGuidance
    let timestamp = Date()
    let includeInHistory: Bool = false
    let includePrefixSound = false
    
    let index: Int
    let waypoint: LocationDetail
    let progress: RouteProgress
    let isAutomatic: Bool
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "waypoint_started"
    }
    
    var prefixSound: Sound? {
        return GlyphSound(.mobilitySense)
    }
    
    init(index: Int, waypoint: LocationDetail, progress: RouteProgress, isAutomatic: Bool) {
        self.index = index
        self.waypoint = waypoint
        self.progress = progress
        self.isAutomatic = isAutomatic
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds {
        // Start with the flag found sound
        var sounds: [Sound] = []
                
        if includePrefixSound, let prefixSound = prefixSound {
            sounds.append(prefixSound)
        }
        
        let beaconOn: String
        if let location = location {
            let distance = location.distance(from: waypoint.location)
            let formattedDistance = LanguageFormatter.string(from: distance, rounded: true)
            
            beaconOn = GDLocalizedString("behavior.scavenger_hunt.callout.next_flag",
                                         waypoint.displayName,
                                         formattedDistance,
                                         String(index + 1),
                                         String(progress.total))
        } else {
            beaconOn = GDLocalizedString("behavior.scavenger_hunt.callout.next_flag.no_distance",
                                         waypoint.displayName,
                                         String(index + 1),
                                         String(progress.total))
        }
        
        sounds.append(TTSSound(beaconOn, at: waypoint.location))
        
        if let departure = waypoint.departureCallout {
            sounds.append(TTSSound(departure, at: waypoint.location))
        }
        
        return Sounds(sounds)
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool) -> String? {
        guard let location = location else {
            return nil
        }
        
        let distance = location.distance(from: waypoint.location)
        
        if tts {
            return LanguageFormatter.spellOutDistance(distance)
        }
        
        return LanguageFormatter.string(from: distance)
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        // This callout type doesn't have a matching card, so no more info description is needed
        return GDLocalizationUnnecessary("")
    }
}
