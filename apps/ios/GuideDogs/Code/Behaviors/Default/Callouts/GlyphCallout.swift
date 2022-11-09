//
//  GlyphCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class GlyphCallout: CalloutProtocol {
    let id = UUID()
    
    let origin: CalloutOrigin
    
    let timestamp = Date()
    
    let includeInHistory = false
    
    var debugDescription: String {
        return "[GlyphCallout] \(glyph.rawValue)"
    }
    
    var logCategory: String {
        return "glyph"
    }
    
    let includePrefixSound = true
    
    var prefixSound: Sound? {
        return nil
    }
    
    /// Resource name of the earcon
    var glyph: StaticAudioEngineAsset
    
    var position: Double?
    
    init(_ calloutOrigin: CalloutOrigin, _ glyph: StaticAudioEngineAsset, position: Double? = nil) {
        self.origin = calloutOrigin
        self.glyph = glyph
        self.position = position
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        guard let position = position else {
            return Sounds(GlyphSound(glyph))
        }
        
        return Sounds(GlyphSound(glyph, compass: position))
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool = false) -> String? {
        return nil
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        return GDLocalizedString("announced_name", timeDescription)
    }
}

class RelativeGlyphCallout: GlyphCallout {
    
    override func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        guard let position = position else {
            return Sounds(GlyphSound(glyph))
        }
        
        return Sounds(GlyphSound(glyph, direction: position))
    }
    
}
