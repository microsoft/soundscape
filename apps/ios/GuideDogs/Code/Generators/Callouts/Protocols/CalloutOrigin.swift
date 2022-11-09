//
//  CalloutOrigin.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

/// Struct representing the possible points of origin for callouts. This is
/// defined as a struct so that it can be extended in the same fashion as
/// with `Notification.Name`.
struct CalloutOrigin: RawRepresentable, Equatable, Hashable {
    typealias RawValue = String
    
    var rawValue: String
    
    var localizedString: String

    var localizedStringForAccessibility: String {
        return localizedString.lowercasedWithAppLocale().replacingOccurrences(of: "callout", with: "call out")
    }
    
    init?(rawValue: String) {
        self.rawValue = rawValue
        localizedString = ""
    }
    
    init?(rawValue: String, localizedString: String) {
        self.init(rawValue: rawValue)
        self.localizedString = localizedString
    }
    
    static let auto = CalloutOrigin(rawValue: "auto", localizedString: GDLocalizedString("callouts.automatic_callouts"))!
    static let intersection = CalloutOrigin(rawValue: "intersection", localizedString: GDLocalizedString("callouts.intersection_callout"))!
    static let explore = CalloutOrigin(rawValue: "explore", localizedString: GDLocalizedString("callouts.ahead_of_you"))!
    static let orient = CalloutOrigin(rawValue: "orient", localizedString: GDLocalizedString("callouts.around_you"))!
    static let nearbyMarkers = CalloutOrigin(rawValue: "nearby_markers", localizedString: GDLocalizedString("callouts.marked_points"))!
    static let locate = CalloutOrigin(rawValue: "locate", localizedString: GDLocalizedString("directions.my_location"))!
    static let beaconChanged = CalloutOrigin(rawValue: "beacon_changed", localizedString: GDLocalizationUnnecessary("BEACON CHANGED"))!
    static let beaconGeofence = CalloutOrigin(rawValue: "beacon_geofence", localizedString: GDLocalizationUnnecessary("BEACON GEOFENCE"))!
    static let system = CalloutOrigin(rawValue: "system", localizedString: GDLocalizationUnnecessary("system"))!
    static let preview = CalloutOrigin(rawValue: "preview", localizedString: GDLocalizationUnnecessary("PREVIEW MODE"))!
    static let onboarding = CalloutOrigin(rawValue: "onboarding", localizedString: GDLocalizationUnnecessary("ONBOARDING"))!
}
