//
//  GenericCallout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

class GenericCallout: CalloutProtocol {
    typealias SoundsBuilder = (_ location: CLLocation?, _ isRepeat: Bool, _ automotive: Bool) -> [Sound]
    
    let id = UUID()
    
    let origin: CalloutOrigin
    
    let timestamp = Date()
    
    let includeInHistory = false
    
    var debugDescription: String {
        return "[GenericCallout] \(description)"
    }
    
    var logCategory: String {
        return "generic"
    }
    
    let includePrefixSound = false
    
    var prefixSound: Sound? {
        return nil
    }
    
    var builder: SoundsBuilder
    var description: String
    
    init(_ calloutOrigin: CalloutOrigin, description: String = "", soundsBuilder: @escaping SoundsBuilder) {
        self.origin = calloutOrigin
        self.builder = soundsBuilder
        self.description = description
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool = false) -> Sounds {
        return Sounds(builder(location, isRepeat, automotive))
    }
    
    func distanceDescription(for location: CLLocation?, tts: Bool = false) -> String? {
        return nil
    }
    
    func moreInfoDescription(for location: CLLocation?) -> String {
        return GDLocalizedString("announced_name", timeDescription)
    }
}
