//
//  DestinationCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

struct DestinationCallout: POICalloutProtocol {
    let id = UUID()
    let origin: CalloutOrigin
    let timestamp = Date()
    
    let includeInHistory = false
    
    var debugDescription: String {
        return ""
    }
    
    var logCategory: String {
        return "destination"
    }
    
    let includePrefixSound = true
    
    var prefixSound: Sound? {
        return GlyphSound(.startJourney)
    }
    
    /// Should be true if this DestinationCallout was the result of the user entering the beacon
    /// geofence and it caused the beacon audio to be disabled/muted. If the beacon was already
    /// off, or this callout was not the result of the user entering the beacon geofence, then
    /// it didn't cause the audio to be disabled/muted, so this property should be false.
    var causedAudioDisabled: Bool
    
    var entityKey: String
    
    var key: String {
        return entityKey
    }
    
    var marker: ReferenceEntity? {
        return SpatialDataCache.referenceEntityByEntityKey(key)
    }
    
    /// A computed property for accessing the POI referenced by the key stored in this Callout object. Note
    /// that we only store the POI's key and not the POI itself due to threading constraints with Realm.
    /// Also note that destinations are always markers, so the POI is obtained through the marker object.
    var poi: POI? {
        return marker?.getPOI()
    }
    
    init(_ calloutOrigin: CalloutOrigin, _ entityKey: String, _ causedAudioDisabled: Bool = false) {
        self.origin = calloutOrigin
        self.entityKey = entityKey
        self.causedAudioDisabled = causedAudioDisabled
    }
    
    func hasSameEntity(_ rhs: POICallout) -> Bool {
        return entityKey == rhs.key
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        guard let marker = marker, let location = location else {
            return Sounds.empty
        }
        
        let markerLocation = marker.closestLocation(from: location)
        
        switch origin {
        case .auto, .beaconChanged, .preview:
            var sounds = [Sound]()
            
            if includePrefixSound {
                let category = SuperCategory(rawValue: marker.getPOI().superCategory) ?? SuperCategory.undefined
                sounds.append(GlyphSound(category.glyph, at: markerLocation))
            }
            
            let formattedDistance = LanguageFormatter.string(from: marker.distanceToClosestLocation(from: location),
                                                             accuracy: location.horizontalAccuracy,
                                                             name: GDLocalizedString("beacon.generic_name"))
            sounds.append(TTSSound(formattedDistance, at: markerLocation))
            
            return Sounds(sounds)
            
        case .beaconGeofence:
            let formattedDistance = LanguageFormatter.formattedDistance(from: DestinationManager.EnterImmediateVicinityDistance)
            
            // Inform the user why the audio beacon has stopped
            if causedAudioDisabled {
                let earcon = GlyphSound(.beaconFound)
                let tts = TTSSound(GDLocalizedString("beacon.beacon_location_within_audio_beacon_muted", formattedDistance), at: markerLocation)
                
                guard let layered = LayeredSound(earcon, tts) else {
                    return Sounds([earcon, tts])
                }
                
                return Sounds(layered)
            }
            
            return Sounds(TTSSound(GDLocalizedString("beacon.beacon_location_within", formattedDistance), at: markerLocation))
            
        default:
            // This callout should only originate from .auto, .beaconChanged, or .beaconGeofence
            return Sounds.empty
        }
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        guard let locationDescription = distanceDescription(for: location, tts: true) else {
            return GDLocalizedString("beacon_distance_update.announced_name", timeDescription)
        }
        
        return GDLocalizedString("beacon_distance_update.announced_name_distance", timeDescription, locationDescription)
    }
}
