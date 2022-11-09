//
//  SecondaryRoadsContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Represents secondary road types.
///
/// In road or intersection detection logic, this is be used to determine how to handle secondary roads,
/// such as to include or exclude specific types, like service roads or walking paths.
enum SecondaryRoadsContext {
    /// Represents the default secondary road types, such as walking paths.
    case standard
    
    /// Represents secondary road types applicable in an automotive state, such as walking paths and service roads.
    case automotive
    
    /// Represents all the secondary road types which are unnamed, such as walking paths, service roads and residential streets.
    case strict
}

extension SecondaryRoadsContext {
    
    private static var standardSecondaryRoadTypes = ["walking_path",
                                                     "bicycle_path",
                                                     "crossing",
                                                     "steps",
                                                     "merging_lane"]
    
    private static var automotiveSecondaryRoadTypes = standardSecondaryRoadTypes + ["road",
                                                                                    "service_road"]
    
    private static var strictSecondaryRoadTypes = automotiveSecondaryRoadTypes + ["residential_street",
                                                                                  "pedestrian_street"]
    
    /// A list of road types Soundscape considers secondary, depending on the context.
    var secondaryRoadTypes: [String] {
        switch self {
        case .standard:
            return SecondaryRoadsContext.standardSecondaryRoadTypes
        case .automotive:
            return SecondaryRoadsContext.automotiveSecondaryRoadTypes
        case .strict:
            return SecondaryRoadsContext.strictSecondaryRoadTypes
        }
    }
    
    /// A list of localized road names Soundscape considers secondary, depending on the context.
    var localizedSecondaryRoadNames: [String] {
        // Type -> localization key -> localized string
        // "walking_path" -> "osm.tag.walking_path" -> "Walking Path" (en-US)
        return secondaryRoadTypes.map { GDLocalizedString("osm.tag.\($0)") }
    }
    
}
