//
//  LocationCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct LocationCallout: LocationCalloutProtocol {
    
    // MARK: Properties
    
    let id = UUID()
    
    let origin: CalloutOrigin
    
    let timestamp = Date()
    
    let geocoderResult: GenericGeocoderResult
    
    let includePrefixSound: Bool
    
    let useClosestRoadIfAvailable: Bool
    
    // MARK: Computed Properties
    
    var generatedAt: CLLocation {
        return geocoderResult.location
    }
    
    var includeInHistory: Bool {
        return poi != nil || road != nil
    }
    
    var debugDescription: String {
        return GDLocalizationUnnecessary("")
    }
    
    var logCategory: String {
        return "location"
    }
    
    var defaultMarkerName: String {
        if let poiComponents = geocoderResult.getPOICalloutComponents() {
            return GDLocalizedString("markers.marker_distance_from_poi", LanguageFormatter.string(from: poiComponents.distance, rounded: true), poiComponents.name)
        } else if let roadComponents = geocoderResult.getRoadCalloutComponents() {
            return GDLocalizedString("markers.marker_distance_from_poi", LanguageFormatter.string(from: roadComponents.distance, rounded: true), roadComponents.name)
        } else {
            // Create a generic name in the form: "Marker created on Feb 29, 2016 at 12:24 PM"
            let formatter = DateFormatter()
            formatter.locale = LocalizationContext.currentAppLocale
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return GDLocalizedString("markers.marker_created_on", formatter.string(from: Date()))
        }
    }
    
    var poi: POI? {
        return geocoderResult.poi
    }
    
    var road: Road? {
        return geocoderResult.road
    }
    
    init(_ calloutOrigin: CalloutOrigin, geocodedResult: GenericGeocoderResult, sound playCategorySound: Bool = false, useClosest: Bool = false) {
        self.origin = calloutOrigin
        self.geocoderResult = geocodedResult
        self.includePrefixSound = playCategorySound
        self.useClosestRoadIfAvailable = useClosest
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        var sounds: [Sound] = []
        
        // If we aren't playing the mode enter/exit sounds, play the category sound instead
        if includePrefixSound {
            sounds.append(GlyphSound(.locationSense, direction: .ahead))
        }
        
        if !isRepeat {
            let roadComponents = geocoderResult.getRoadCalloutComponents(fromLocation: location, useClosest: useClosestRoadIfAvailable)
            let poiComponents = geocoderResult.getPOICalloutComponents(fromLocation: location)
            
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
            
                if let roadComponents = roadComponents {
                    let string = GDLocalizedString("directions.nearest_road_name_is_distance_direction", roadComponents.name, roadComponents.formattedDistance, roadComponents.encodedDirection)
                    sounds.append(TTSSound(string, at: roadComponents.location))
                }
            
                if let poiComponents = poiComponents {
                    let string = GDLocalizedString("directions.poi_name_is_distance_direction", poiComponents.name, poiComponents.formattedDistance, poiComponents.encodedDirection)
                    sounds.append(TTSSound(string, at: poiComponents.location))
                }
            } else {
                if roadComponents == nil && poiComponents == nil {
                    let string = GDLocalizedString("general.error.heading")
                    sounds.append(TTSSound(string, direction: .ahead))
                } else {
                    if let roadComponents = roadComponents {
                        let string = GDLocalizedString("directions.nearest_road_name_is_distance", roadComponents.name, roadComponents.formattedDistance)
                        sounds.append(TTSSound(string, direction: .ahead))
                    }
                    
                    if let poiComponents = poiComponents {
                        let string = GDLocalizedString("directions.poi_name_is_distance", poiComponents.name, poiComponents.formattedDistance)
                        sounds.append(TTSSound(string, direction: .ahead))
                    }
                }
            }
        } else {
            sounds.append(TTSSound(GDLocalizedString("directions.previous_location"), direction: .ahead))
            
            if let roadComponents = geocoderResult.getRoadCalloutComponents(useClosest: useClosestRoadIfAvailable, useOriginalHeading: true) {
                let string = GDLocalizedString("directions.nearest_road_name_was_distance_direction", roadComponents.name, roadComponents.formattedDistance, roadComponents.encodedDirection)
                sounds.append(TTSSound(string, at: roadComponents.location))
            }
            
            if let poiComponents = geocoderResult.getPOICalloutComponents(useOriginalHeading: true) {
                let string = GDLocalizedString("directions.poi_name_was_distance_direction", poiComponents.name, poiComponents.formattedDistance, poiComponents.encodedDirection)
                sounds.append(TTSSound(string, at: poiComponents.location))
            }
        }
        
        return Sounds(sounds)
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        guard let locationDescription = distanceDescription(for: location, tts: true) else {
            return GDLocalizedString("previous_location.announced_name", timeDescription)
        }
        
        return GDLocalizedString("previous_location.announced_name_distance", timeDescription, locationDescription)
    }
}
