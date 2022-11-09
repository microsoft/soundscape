//
//  AlongRoadLocationCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import CocoaLumberjackSwift

struct AlongRoadLocationCallout: LocationCalloutProtocol {
    
    private static let thresholdForIntersectionDistanceCallout = CLLocationDistance(500)
    
    // MARK: Properties
    
    let id = UUID()
    
    let origin: CalloutOrigin
    
    let timestamp = Date()
    
    let includeInHistory = true
    
    let geocoderResult: AlongsideGeocoderResult
    
    let includePrefixSound: Bool
    
    let useClosestRoadIfAvailable: Bool
    
    // MARK: Computed Properties
    
    var generatedAt: CLLocation {
        return geocoderResult.location
    }
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "along_road_location"
    }
    
    var defaultMarkerName: String {
        return GDLocalizedString("markers.marker_along", road?.localizedName ?? GDLocalizedString("directions.unknown_road"))
    }
    
    var road: Road? {
        return useClosestRoadIfAvailable ? geocoderResult.closestRoad : geocoderResult.road
    }
    
    var intersection: Intersection? {
        return geocoderResult.intersection
    }
    
    var estimatedAddress: String? {
        guard let estimatedAddress = geocoderResult.estimatedAddress else {
            return nil
        }
        
        guard let roadName = road?.localizedName else {
            DDLogDebug("Address in Locate - Road name is `nil`")
            return nil
        }
        
        // If address does not match the road that the user is on,
        // do not return an address
        guard Address.addressContainsStreet(address: estimatedAddress.streetName, streetName: roadName) else {
            DDLogDebug("Address in Locate - Address and nearest road do not match - address: \"\(estimatedAddress)\", nearest road: \"\(roadName)\"")
            return nil
        }
        
        // If we cannot parse the street number, do not return
        // an address
        return estimatedAddress.subThoroughfare
    }
    
    // Inside Building
    init(_ calloutOrigin: CalloutOrigin, geocodedResult: AlongsideGeocoderResult, sound playCategorySound: Bool = false, useClosest: Bool = false) {
        self.origin = calloutOrigin
        self.geocoderResult = geocodedResult
        self.includePrefixSound = playCategorySound
        self.useClosestRoadIfAvailable = useClosest
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        let direction = geocoderResult.heading.value
        let useAutomotive = automotive && geocoderResult.heading.isCourse
        
        var sounds: [Sound] = []
        var notificationHandler: AsyncSoundsNotificationHandler?
        var notificationName: Notification.Name?
        var notificationObject: AlongsideGeocoderResult?
        
        guard let roadComponents = geocoderResult.getRoadCalloutComponents(useClosest: useClosestRoadIfAvailable) else {
            return Sounds.empty
        }
        
        // If we aren't playing the mode enter/exit sounds, play the category sound instead
        if includePrefixSound {
            sounds.append(GlyphSound(.locationSense, direction: .ahead))
        }
        
        if !isRepeat {
            // Phrase example 1: Walking along a road in normal mode: "Heading West along Pike Street"
            // Phrase example 2: Walking along a road in compass mode: "Facing West along Pike Street"
            // Phrase example 3: In a vehicle and a valid course: "Traveling West along Pike Street"

            // Create the localization string key
            if let direction = direction {
                let cardinal = CardinalDirection(direction: direction)!.rawValue
                
                var prefix = "facing"
                
                if geocoderResult.heading.isCourse {
                    prefix = (automotive ? "traveling" : "heading")
                }
                
                // "directions.along.traveling.ne" -> "Traveling northeast along <Road ABC>"
                let string = GDLocalizedString("directions.along.\(prefix).\(cardinal)", roadComponents.name)
                
                sounds.append(TTSSound(string, compass: direction))
            } else {
                let string = GDLocalizedString("directions.near_name", roadComponents.name)
                sounds.append(TTSSound(string, direction: .ahead))
            }
            
            // We only append more information (such as intersections or roundabouts) to the callout if a user initiated it
            guard origin == .locate else {
                return Sounds(sounds)
            }
            
            // If address is available, add it to the start of callout
            // else, append it once the rest of the callout completes
            if let estimatedAddress = self.estimatedAddress?.stringWithSpelledOutDigits(withLocale: LocalizationContext.currentAppLocale) {
                sounds.append(TTSSound(GDLocalizedString("directions.near_address", estimatedAddress), direction: .ahead))
            } else {
                // If we don't have an address yet,
                // listen for completion notification
                notificationName = Notification.Name.estimatedAddressDidComplete
                notificationObject = geocoderResult
                
                notificationHandler = { (_) -> [Sound] in
                    guard let estimatedAddress = self.estimatedAddress?.stringWithSpelledOutDigits(withLocale: LocalizationContext.currentAppLocale) else {
                        return []
                    }
                    
                    return [TTSSound(GDLocalizedString("directions.near_address", estimatedAddress), direction: .ahead)]
                }
            }
            
            guard let intersection = intersection else {
                return Sounds(sounds)
            }
            
            guard let intComponents = geocoderResult.getIntersectionCalloutComponents(useClosest: useClosestRoadIfAvailable) else {
                return Sounds(sounds)
            }
            
            // Do not append a distance string if the user is in a vehicle and the distance is less than 500 meters
            let distanceString: String?
            
            if useAutomotive,
                let location = location,
                location.distance(from: intersection.location) < AlongRoadLocationCallout.thresholdForIntersectionDistanceCallout {
                distanceString = nil
            } else {
                distanceString = intComponents.formattedDistance
            }
            
            // For direction, use "ahead" when in a vehicle, in any other case use the actual direction
            var directionString: String?
            
            if direction != nil {
                directionString = automotive ? GDLocalizedString("directions.direction.ahead") : intComponents.encodedDirection
            }
            
            if let roundabout = intersection.roundabout, !roundabout.isLarge {
                guard let exitDirections = roundabout.exitDirections(relativeTo: direction ?? Heading.defaultValue) else { return Sounds(sounds) }
                
                let string: String
                if let distanceString = distanceString, let directionString = directionString {
                    // Phrase example 1: "Roundabout with <5> exits <600 meters> <ahead to the left>"
                    string = GDLocalizedString("directions.roundabout_with_exits_distance_direction", String(exitDirections.count), distanceString, directionString)
                } else if let directionString = directionString {
                    // Phrase example 2: "Roundabout with <5> exits <ahead>"
                    string = GDLocalizedString("directions.roundabout_with_exits_direction", String(exitDirections.count), directionString)
                } else if let distanceString = distanceString {
                    // Phrase example 3: "Roundabout with <5> exits <600 meters> away"
                    string = GDLocalizedString("directions.roundabout_with_exits_distance", distanceString)
                } else {
                    // Phrase example 3: "Roundabout with <5> exits nearby"
                    string = GDLocalizedString("directions.roundabout_with_exits")
                }
                
                sounds.append(TTSSound(string, compass: intComponents.bearing))
            } else {
                let string: String
                if let distanceString = distanceString, let directionString = directionString {
                    // Phrase example 1: "Intersection with <Pike Street> <600 meters> <ahead to the left>"
                    string = GDLocalizedString("directions.intersection_with_name_distance_direction", intComponents.name, distanceString, directionString)
                } else if let directionString = directionString {
                    // Phrase example 2: "Intersection with <Pike Street> <ahead>"
                    string = GDLocalizedString("directions.intersection_with_name_direction", intComponents.name, directionString)
                } else if let distanceString = distanceString {
                    // Phrase example 2: "Intersection with <Pike Street> <600 meters> away"
                    string = GDLocalizedString("directions.intersection_with_name_distance", intComponents.name, distanceString)
                } else {
                    // Phrase example 2: "Intersection with <Pike Street> nearby"
                    string = GDLocalizedString("directions.intersection_with_name", intComponents.name)
                }
                
                sounds.append(TTSSound(string, compass: intComponents.bearing))
            }
        } else {
            sounds.append(TTSSound(GDLocalizedString("directions.previous_location_along", roadComponents.name), direction: .ahead))
            
            // Add address to callout
            if let estimatedAddress = self.estimatedAddress?.stringWithSpelledOutDigits(withLocale: LocalizationContext.currentAppLocale) {
                sounds.append(TTSSound(GDLocalizedString("directions.near_address", estimatedAddress), direction: .ahead))
            }
            
            guard let intersection = intersection else {
                return Sounds(sounds)
            }
            
            guard let intComponents = geocoderResult.getIntersectionCalloutComponents(useClosest: useClosestRoadIfAvailable, useOriginalHeading: true) else {
                return Sounds(sounds)
            }
            
            if let roundabout = intersection.roundabout, !roundabout.isLarge {
                guard let exitDirections = roundabout.exitDirections(relativeTo: direction ?? Heading.defaultValue) else { return Sounds(sounds) }
                let string = GDLocalizedString("directions.roundabout_with_exits_was_distance_direction",
                                               String(exitDirections.count),
                                               intComponents.formattedDistance,
                                               intComponents.encodedDirection)
                
                sounds.append(TTSSound(string, compass: intComponents.bearing))
            } else {
                let string = GDLocalizedString("directions.intersection_with_name_was_distance_direction",
                                               intComponents.name,
                                               intComponents.formattedDistance,
                                               intComponents.encodedDirection)
                
                sounds.append(TTSSound(string, compass: intComponents.bearing))
            }
        }
        
        return Sounds(soundArray: sounds,
                      onNotificationHandler: notificationHandler,
                      notificationName: notificationName,
                      notificationObject: notificationObject)
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        guard let locationDescription = distanceDescription(for: location, tts: true) else {
            return GDLocalizedString("previous_location.announced_name", timeDescription)
        }
        
        return GDLocalizedString("previous_location.announced_name_distance", timeDescription, locationDescription)
    }
}
