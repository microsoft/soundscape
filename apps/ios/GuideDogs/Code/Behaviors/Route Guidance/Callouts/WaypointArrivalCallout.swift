//
//  WaypointArrivalCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension CalloutOrigin {
    static let routeGuidance = CalloutOrigin(rawValue: "route_guidance", localizedString: GDLocalizedString("route_detail.name.default"))!
}

class WaypointArrivalCallout: CalloutProtocol {
    let id = UUID()
    
    let origin: CalloutOrigin = .routeGuidance
    
    let timestamp = Date()
    
    let includeInHistory: Bool = true
    
    let index: Int
    
    let waypoint: LocationDetail
    
    let progress: RouteProgress
    
    let previouslyVisited: Bool
    
    let isAdaptiveSportsActivity: Bool
    
    let includePrefixSound = false
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "waypoint_visited"
    }
    
    var prefixSound: Sound? {
        return GlyphSound(.mobilitySense)
    }
    
    init(index: Int, waypoint: LocationDetail, progress: RouteProgress, previouslyVisited: Bool, isAdaptiveSportsActivity: Bool) {
        self.index = index
        self.waypoint = waypoint
        self.progress = progress
        self.previouslyVisited = previouslyVisited
        self.isAdaptiveSportsActivity = isAdaptiveSportsActivity
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds {
        // Start with the flag found sound
        var sounds: [Sound] = []
                
        if includePrefixSound {
            sounds.append(GlyphSound(.flagFound, at: waypoint.location))
        }
        
        if isAdaptiveSportsActivity {
            sounds.append(GlyphSound(.beaconFound))
        }
        
        // Add sound about the arrival
        let waypointNearby = GDLocalizedString("behavior.scavenger_hunt.callout.nearby_with_name", waypoint.displayName)
        sounds.append(TTSSound(waypointNearby, at: waypoint.location))
        
        if let arrival = waypoint.arrivalCallout {
            sounds.append(TTSSound(arrival, at: waypoint.location))
        }
        
        // Add a sound about the current state of the route guidance
        guard !previouslyVisited, progress.isDone else {
            return Sounds(sounds)
        }
        
        guard isAdaptiveSportsActivity else {
            // If this is a normal route, then use a more simple finish
            let complete = GDLocalizedString("routes.callout.complete")
            sounds.append(TTSSound(complete, at: waypoint.location))
            return Sounds(sounds)
        }
        
        // If this is an adaptive sports event, finish with a little pagentry
        sounds.append(GlyphSound(.huntComplete, at: waypoint.location))
        
        let congrats = GDLocalizedString("behavior.scavenger_hunt.callout.complete")
        sounds.append(TTSSound(congrats, at: waypoint.location))
        
        let muted = GDLocalizedString("behavior.scavenger_hunt.callout.pausing_hunt")
        sounds.append(TTSSound(muted, at: waypoint.location))
        
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
