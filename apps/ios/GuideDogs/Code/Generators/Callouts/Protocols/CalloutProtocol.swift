//
//  CalloutProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.

import CoreLocation

protocol CalloutProtocol {
    var id: UUID { get }
    
    var origin: CalloutOrigin { get }
    
    var timestamp: Date { get }
    
    var includeInHistory: Bool { get }
    
    var debugDescription: String { get }
    
    /// A general callout type description, such as "intersection", "poi" or "location"
    var logCategory: String { get }
    
    var includePrefixSound: Bool { get }
    
    var prefixSound: Sound? { get }
    
    func sounds(for location: CLLocation?, isRepeat: Bool, automotive: Bool) -> Sounds
    
    func distanceDescription(for location: CLLocation?, tts: Bool) -> String?
    
    func moreInfoDescription(for location: CLLocation?) -> String
    
    func equals(rhs: CalloutProtocol) -> Bool
}

extension CalloutProtocol {
    var timeDescription: String {
        // TODO: Consider refactoring with a "TimeAgo" library, such as
        // `DateTools` for Swift for a more robust time ago description.
        
        let elapsed = Int(Date().timeIntervalSince(timestamp)) / 60
        
        if elapsed < 1 {
            return GDLocalizedString("time.just_now")
        } else if elapsed == 1 {
            return GDLocalizedString("time.one_minute_ago")
        } else if elapsed > 1 && elapsed < 60 {
            return GDLocalizedString("time.num_minutes_ago", String(elapsed))
        } else if elapsed == 60 {
            return GDLocalizedString("time.one_hour_ago")
        } else {
            return GDLocalizedString("time.over_one_hour_ago")
        }
    }
    
    func sounds(for location: CLLocation?, isRepeat: Bool = false, automotive: Bool = false) -> Sounds {
        return sounds(for: location, isRepeat: isRepeat, automotive: automotive)
    }
    
    func equals(rhs: CalloutProtocol) -> Bool {
        return id == rhs.id
    }
    
    func logHistoryAction(_ action: String) {
        // If this callout is displayed in the history, find its index
        guard let index = AppContext.shared.calloutHistory.visibleIndex(of: self) else {
            return
        }
        
        // Only 3 types are displayed in History. Figure out which one this is.
        let type: String
        if self is POICallout {
            type = "poi"
        } else if self is IntersectionCallout {
            type = "intersection"
        } else {
            type = "location"
        }
        
        var params: [String: Any] = [:]
        params["type"] = type
        params["index"] = index
        
        GDATelemetry.track("voice_over_action.\(action)", with: ["type:": type, "index": String(index)])
    }
}
