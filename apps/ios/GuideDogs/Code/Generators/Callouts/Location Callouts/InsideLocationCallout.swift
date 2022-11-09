//
//  InsideLocationCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct InsideLocationCallout: LocationCalloutProtocol {
    
    // MARK: Properties
    
    let id = UUID()
    
    let origin: CalloutOrigin
    
    let timestamp = Date()
    
    let includeInHistory = true
    
    let geocoderResult: InsideGeocoderResult
    
    let includePrefixSound: Bool
    
    // MARK: Computed Properties
    
    var generatedAt: CLLocation {
        return geocoderResult.location
    }
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "inside_location"
    }
    
    var defaultMarkerName: String {
        return GDLocalizedString("markers.marker_at", poi?.localizedName ?? GDLocalizedString("poi.unknown_place"))
    }
    
    var poi: POI? {
        return geocoderResult.poi
    }
    
    // Inside Building
    init(_ calloutOrigin: CalloutOrigin, geocodedResult: InsideGeocoderResult, sound playCategorySound: Bool = false) {
        self.origin = calloutOrigin
        self.geocoderResult = geocodedResult
        self.includePrefixSound = playCategorySound
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        var sounds: [Sound] = []
        
        guard let poiComponents = geocoderResult.getCalloutComponents() else {
            return Sounds.empty
        }
        
        // If we aren't playing the mode enter/exit sounds, play the category sound instead
        if includePrefixSound {
            sounds.append(GlyphSound(.locationSense, direction: .ahead))
        }
        
        if !isRepeat {
            // Create the localization string key
            if let direction = geocoderResult.heading.value {
                let cardinal = CardinalDirection(direction: direction)!.rawValue
                
                var prefix = "facing"
                
                if geocoderResult.heading.isCourse {
                    prefix = (automotive ? "traveling" : "heading")
                }
                
                // "directions.traveling.ne" -> "Traveling northeast"
                let string = GDLocalizedString("directions.\(prefix).\(cardinal)")
                
                sounds.append(TTSSound(string, compass: direction))
            }
        } else {
            sounds.append(TTSSound(GDLocalizedString("directions.previous_location"), direction: .ahead))
        }
        sounds.append(TTSSound(GDLocalizedString("directions.at_poi", poiComponents.name), at: poiComponents.location))
        
        return Sounds(sounds)
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        guard let locationDescription = distanceDescription(for: location, tts: true) else {
            return GDLocalizedString("previous_location.announced_name", timeDescription)
        }
        
        return GDLocalizedString("previous_location.announced_name_distance", timeDescription, locationDescription)
    }
}
