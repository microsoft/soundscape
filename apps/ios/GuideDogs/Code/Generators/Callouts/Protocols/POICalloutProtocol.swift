//
//  POICalloutProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

protocol POICalloutProtocol: CalloutProtocol {
    var key: String { get }
    
    var poi: POI? { get }
    
    var marker: ReferenceEntity? { get }
}

extension POICalloutProtocol {
    var prefixSound: Sound? {
        guard let poi = poi else {
            return nil
        }
        
        let category = SuperCategory(rawValue: poi.superCategory) ?? SuperCategory.undefined
        
        return GlyphSound(category.glyph)
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool = false) -> String? {
        guard let location = location, let distance = poi?.distanceToClosestLocation(from: location) else {
            return nil
        }
        
        if tts {
            return LanguageFormatter.spellOutDistance(distance)
        }
        
        return LanguageFormatter.string(from: distance)
    }
}
