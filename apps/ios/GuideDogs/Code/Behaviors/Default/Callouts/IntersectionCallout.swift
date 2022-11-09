//
//  IntersectionCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import CocoaLumberjackSwift

struct IntersectionCallout: CalloutProtocol {
    
    let id = UUID()
    let origin: CalloutOrigin
    let timestamp = Date()
    let isRoundabout: Bool
    let includeInHistory = true
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "intersection"
    }
    
    let includePrefixSound = true
    
    var prefixSound: Sound? {
        return GlyphSound(SuperCategory.intersections.glyph)
    }
    
    let key: String
    let heading: CLLocationDirection
    
    var intersection: Intersection? {
        return SpatialDataCache.intersectionByKey(key)
    }
    
    init(_ calloutOrigin: CalloutOrigin, _ intersectionKey: String, _ isRoundabout: Bool = false, _ userHeading: CLLocationDirection) {
        self.origin = calloutOrigin
        self.key = intersectionKey
        self.isRoundabout = isRoundabout
        self.heading = userHeading
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        guard let intersection = intersection else {
            return Sounds.empty
        }
        
        // Construct the output phrase
        var sounds: [Sound] = []
        
        // Add the sound effect
        if includePrefixSound {
            sounds.append(GlyphSound(.poiSense, direction: .ahead))
        }
        
        if isRepeat {
            guard let location = location else {
                return Sounds.empty
            }
            
            // If this is a repeat and the user isn't next to the intersection anymore, switch to using the
            // intersection's name instead of the road directions.
            if location.distance(from: intersection.location) > IntersectionGenerator.arrivalDistance {
                if isRoundabout, let roundabout = intersection.roundabout, !roundabout.isLarge {
                    // "Pike roundabout" ("Pike" is the roundabout name)
                    sounds.append(contentsOf: IntersectionCallout.roundaboutSounds(roundabout: roundabout,
                                                                                   relativeTo: heading,
                                                                                   withoutExits: true))
                } else {
                    // "Harrison St. and 9th Ave N Intersection"
                    let name = GDLocalizedString("intersection.named_intersection", intersection.localizedName)
                    sounds.append(TTSSound(name, at: intersection.location))
                }
                
                return Sounds(sounds)
            }
        }
        
        if isRoundabout, let roundabout = intersection.roundabout, !roundabout.isLarge {
            sounds.append(contentsOf: IntersectionCallout.roundaboutSounds(roundabout: roundabout, relativeTo: heading))
        } else {
            sounds.append(contentsOf: IntersectionCallout.intersectionSounds(intersection: intersection, relativeTo: heading))
        }

        return Sounds(sounds)
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool = false) -> String? {
        guard let location = location else {
            return nil
        }
        
        guard let intersection = intersection else {
            return nil
        }
        
        let distance = location.distance(from: intersection.location)
        
        if tts {
            return LanguageFormatter.spellOutDistance(distance)
        }
        
        return LanguageFormatter.string(from: distance)
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        guard let locationDescription = distanceDescription(for: location, tts: true) else {
            return GDLocalizedString("intersection_callout.announced_name", timeDescription)
        }
        
        return GDLocalizedString("intersection_callout.announced_name_distance", timeDescription, locationDescription)
    }
    
}

// MARK: - Sounds

extension IntersectionCallout {
    
    private static func sounds(for directions: [RoadDirection],
                               relativeTo heading: CLLocationDirection,
                               roundabout: Bool = false) -> [Sound]? {
        
        func leftSound(_ direction: RoadDirection) -> Sound {
            let string = roundabout ? GDLocalizedString("directions.name_goes_left.roundabout", direction.road.localizedName) :
                                      GDLocalizedString("directions.name_goes_left", direction.road.localizedName)
            
            let position = heading.add(degrees: .left)
            return TTSSound(string + ".", compass: position)
        }
        
        func aheadSound(_ direction: RoadDirection) -> Sound {
            let string = roundabout ? GDLocalizedString("directions.name_continues_ahead.roundabout", direction.road.localizedName) :
                                      GDLocalizedString("directions.name_continues_ahead", direction.road.localizedName)
            
            return TTSSound(string + ".", compass: heading)
        }
        
        func rightSound(_ direction: RoadDirection) -> Sound {
            let string = roundabout ? GDLocalizedString("directions.name_goes_right.roundabout", direction.road.localizedName) :
                                      GDLocalizedString("directions.name_goes_right", direction.road.localizedName)
            
            let position = heading.add(degrees: .right)
            return TTSSound(string + ".", compass: position)
        }
        
        var phrases: [Sound] = []
        
        for direction in directions {
            switch direction.direction {
            case .behindLeft, .left, .aheadLeft: phrases.append(leftSound(direction))
            case .behindRight, .right, .aheadRight: phrases.append(rightSound(direction))
            case .ahead: phrases.append(aheadSound(direction))
            default: continue
            }
        }
        
        return phrases
    }
    
    // MARK: Intersection

    /// Example output 1: "Approaching intersection. Road A, goes left. Road B, goes right."
    private static func intersectionSounds(intersection: Intersection, relativeTo direction: CLLocationDirection) -> [Sound] {
        // Phrase prefix
        let string = GDLocalizedString("intersection.approaching_intersection")
        var sounds: [Sound] = [TTSSound(string + ".", at: intersection.location)]

        // Add direction sounds
        if let directionSounds = IntersectionCallout.directionSounds(intersection: intersection, relativeTo: direction) {
            sounds.append(contentsOf: directionSounds)
        }
        
        return sounds
    }
    
    // This will return a spatialized array of directions of the roads the intersection intersects.
    // For example: ["Road A, goes left.", "Road B, continues ahead.", "Road C, goes right."]
    static func directionSounds(intersection: Intersection,
                                relativeTo direction: CLLocationDirection,
                                roundabout: Bool = false) -> [Sound]? {
        guard let roadDirections = intersection.directions(relativeTo: direction), roadDirections.count > 0 else {
            DDLogWarn("[INT] No road directions")
            return nil
        }
        
        return IntersectionCallout.sounds(for: roadDirections, relativeTo: direction, roundabout: roundabout)
    }
    
    // MARK: Roundabout

    private static let maxRoundaboutExitsToCallout = 4
    
    /// Example output 1: "Approaching [roundabout name] roundabout. Road A, goes left. Road B, goes right."
    /// Example output 2: "Approaching roundabout with 6 exits."
    /// Example output 3: "Roundabout. Road A, goes left. Road B, goes right."
    private static func roundaboutSounds(roundabout: Roundabout, relativeTo direction: CLLocationDirection, withoutExits: Bool = false) -> [Sound] {
        let roundaboutName: String
        let hasRoundaboutInName: Bool
        let genericRoundaboutName = GDLocalizedString("osm.tag.roundabout")
        
        if let rLocalizedName = roundabout.localizedName {
            roundaboutName = rLocalizedName
            hasRoundaboutInName = rLocalizedName.lowercasedWithAppLocale().contains(genericRoundaboutName)
        } else {
            roundaboutName = genericRoundaboutName
            hasRoundaboutInName = true
        }
        
        let string: String
        
        guard !withoutExits else {
            if !hasRoundaboutInName {
                // "Pike roundabout" ("Pike" is the roundabout name)
                string = GDLocalizedString("directions.name_roundabout", roundaboutName)
            } else {
                // "Pike roundabout" (Pike roundabout" is the roundabout name)
                string = roundaboutName
            }
            
            return [TTSSound(string + ".", at: roundabout.intersection.location)]
        }
        
        if !hasRoundaboutInName {
            // "Approaching Pike roundabout" ("Pike" is the roundabout name)
            string = GDLocalizedString("directions.approaching_name_roundabout", roundaboutName)
        } else {
            // "Approaching Pike roundabout" ("Pike roundabout" is the roundabout name)
            string = GDLocalizedString("directions.approaching_name", roundaboutName)
        }
        
        var sounds: [Sound] = [TTSSound(string + ".", at: roundabout.intersection.location)]
        
        guard let exitDirections = roundabout.exitDirections(relativeTo: direction) else { return sounds }
        guard let exitSounds = IntersectionCallout.directionSounds(roadDirections: exitDirections, relativeTo: direction) else { return sounds }
        
        // Add direction sounds
        if exitSounds.count > IntersectionCallout.maxRoundaboutExitsToCallout {
            // Because there a lot of exits to callout, use a short phrase with the number of exits
            
            let string: String
            if !hasRoundaboutInName {
                // "Approaching Pike roundabout with 3 exits" ("Pike" is the roundabout name)
                string = GDLocalizedString("directions.approaching_name_roundabout_with_exits", roundaboutName, String(exitDirections.count))
            } else {
                // "Approaching Pike roundabout with 3 exits" ("Pike roundabout" is the roundabout name)
                string = GDLocalizedString("directions.approaching_name_with_exits", roundaboutName, String(exitDirections.count))
            }
            
            sounds = [TTSSound(string + ".", at: roundabout.intersection.location)]
        } else {
            sounds.append(contentsOf: exitSounds)
        }
        
        return sounds
    }
    
    static func directionSounds(roadDirections: [RoadDirection],
                                relativeTo direction: CLLocationDirection) -> [Sound]? {
        guard !roadDirections.isEmpty else {
            DDLogWarn("[INT] No road directions")
            return nil
        }
        
        return IntersectionCallout.sounds(for: roadDirections, relativeTo: direction)
    }
    
    private static func directionSounds(roundabout: Roundabout, relativeTo direction: CLLocationDirection) -> [Sound]? {
        // Get the roads directions
        guard let roadDirections = roundabout.exitDirections(relativeTo: direction), roadDirections.count > 0 else {
            DDLogWarn("[INT] No road directions")
            return nil
        }
        
        return IntersectionCallout.sounds(for: roadDirections, relativeTo: direction)
    }
}
