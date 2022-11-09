//
//  StringCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

class StringCallout: CalloutProtocol {
    let id = UUID()
    
    let origin: CalloutOrigin
    
    let timestamp = Date()
    
    let includeInHistory = false
    
    var debugDescription: String {
        return "[StringCallout] \(callout)"
    }
    
    var logCategory: String {
        return "string"
    }
    
    let includePrefixSound = true
    
    var prefixSound: Sound? {
        return nil
    }
    
    var glyph: StaticAudioEngineAsset?
    var callout: String
    var position: Double?
    var location: CLLocation?
    
    init(_ calloutOrigin: CalloutOrigin, _ callout: String, glyph: StaticAudioEngineAsset? = nil) {
        self.origin = calloutOrigin
        self.callout = callout
        self.glyph = glyph
    }
    
    init(_ calloutOrigin: CalloutOrigin, _ callout: String, glyph: StaticAudioEngineAsset? = nil, position: Double?) {
        self.origin = calloutOrigin
        self.callout = callout
        self.glyph = glyph
        self.position = position
    }
    
    init(_ calloutOrigin: CalloutOrigin, _ callout: String, glyph: StaticAudioEngineAsset? = nil, location: CLLocation?) {
        self.origin = calloutOrigin
        self.callout = callout
        self.glyph = glyph
        self.location = location
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        var sounds: [Sound] = []
        
        if let position = position {
            if let glyph = glyph {
                sounds.append(GlyphSound(glyph, compass: position))
            }
            
            sounds.append(TTSSound(callout, compass: position))
        } else if let location = location {
            if let glyph = glyph {
                sounds.append(GlyphSound(glyph, at: location))
            }
            
            sounds.append(TTSSound(callout, at: location))
        } else {
            if let glyph = glyph {
                sounds.append(GlyphSound(glyph))
            }
            
            sounds.append(TTSSound(callout))
        }
        
        return Sounds(sounds)
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool = false) -> String? {
        return nil
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        return GDLocalizedString("announced_name", timeDescription)
    }
}

class RelativeStringCallout: StringCallout {
    
    override func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        guard let position = position else {
            return Sounds(TTSSound(callout))
        }
        
        return Sounds(TTSSound(callout, direction: position))
    }
    
}
