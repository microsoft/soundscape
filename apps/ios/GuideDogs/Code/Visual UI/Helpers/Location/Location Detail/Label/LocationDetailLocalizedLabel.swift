//
//  LocationDetailLocalizedLabel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

struct LocationDetailLocalizedLabel {
    
    // MARK: Properties
    
    let detail: LocationDetail
    
    // MARK: `LocalizedLabel`
    
    // Set `isVerbose = true` to prepend "marker" to the location's name
    // when the location is a marker
    func name(isVerbose: Bool = true) -> LocalizedLabel {
        let text = detail.displayName
        let accessibilityText: String?
        
        if detail.isMarker && isVerbose {
            accessibilityText = GDLocalizedString("markers.marker_with_name", detail.displayName)
        } else {
            accessibilityText = nil
        }
        
        return LocalizedLabel(text: text, accessibilityText: accessibilityText)
    }
    
    var address: LocalizedLabel {
        return LocalizedLabel(text: detail.displayAddress, accessibilityText: nil)
    }
    
    func distance(from userLocation: CLLocation?) -> LocalizedLabel? {
        var text: String?
        var accessibilityText: String?
        
        if let userLocation = userLocation {
            let distance = detail.location.distance(from: userLocation)
            let bearing = userLocation.bearing(to: detail.location)
            
            if distance > 0, bearing >= 0, let direction = CardinalDirection(direction: bearing) {
                // "30 m・NW"
                text = LanguageFormatter.string(from: distance, abbreviated: true) + "・" + direction.localizedAbbreviatedString
                // "30 meters・North West"
                accessibilityText = LanguageFormatter.spellOutDistance(distance) + direction.localizedString
            } else if distance >= 0 {
                // "30 m"
                text = LanguageFormatter.string(from: distance, abbreviated: true)
                // "30 meters"
                accessibilityText = LanguageFormatter.spellOutDistance(distance)
            } else if bearing >= 0, let direction = CardinalDirection(direction: bearing) {
                // "NW"
                text = direction.localizedAbbreviatedString
                // "North West"
                accessibilityText = direction.localizedString
            }
        }
        
        if let text = text {
            return LocalizedLabel(text: text, accessibilityText: accessibilityText)
        } else {
            // Failed to initialize distance label
            return nil
        }
    }
    
    var annotation: LocalizedLabel {
        return LocalizedLabel(text: detail.displayAnnotation, accessibilityText: nil)
    }
    
    func nameAndDistance(from userLocation: CLLocation?) -> LocalizedLabel {
        let name = name()
        
        if let distance = distance(from: userLocation) {
            let text = GDLocalizedString("directions.name_distance", name.text, distance.text)
            let accessibilityText = GDLocalizedString("directions.name_distance", name.accessibilityText ?? name.text, distance.accessibilityText ?? distance.text)
            
            return LocalizedLabel(text: text, accessibilityText: accessibilityText)
        } else {
            return name
        }
    }
    
    var departureCallout: LocalizedLabel? {
        guard let departureCallout = detail.departureCallout else { return nil }
        return LocalizedLabel(text: departureCallout, accessibilityText: nil)
    }
    
    var arrivalCallout: LocalizedLabel? {
        guard let arrivalCallout = detail.arrivalCallout else { return nil }
        return LocalizedLabel(text: arrivalCallout, accessibilityText: nil)
    }
    
}

extension LocationDetail {
    
    var labels: LocationDetailLocalizedLabel {
        return LocationDetailLocalizedLabel(detail: self)
    }
    
}
