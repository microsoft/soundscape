//
//  Category.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

typealias SuperCategories = [SuperCategory: Set<String>]

enum SuperCategory: String {
    // MARK: Super Category Names
    case undefined = "undefined"
    case entrances = "entrance"
    case entranceLists = "entrances"
    case roads = "road"
    case paths = "path"
    case intersections = "intersection"
    case landmarks = "landmark"
    case places = "place"
    case mobility = "mobility"
    case information = "information"
    case objects = "object"
    case safety = "safety"
    case beacons = "beacons"
    case authoredActivity = "authoredActivity"
    
    // MARK: Static Methods
    
    static func parseCategories(from: Data) -> (version: Int, categories: SuperCategories)? {
        do {
            guard let categoryJSON = try JSONSerialization.jsonObject(with: from) as? [String: Any] else {
                return nil
            }
            
            guard let version = categoryJSON["version"] as? Int else {
                return nil
            }
            
            guard let categories = categoryJSON["categories"] as? [String: [String]] else {
                return nil
            }
            
            var mapped: SuperCategories = [:]
            
            for (key, values) in categories {
                // Ignore unknown categories
                if let category = SuperCategory(rawValue: key) {
                    mapped[category] = Set(values)
                }
            }
            
            return (version: version, categories: mapped)
        } catch {
            return nil
        }
    }
    
    var glyph: StaticAudioEngineAsset {
        switch self {
        case .information: return StaticAudioEngineAsset.infoAlert
        case .mobility: return StaticAudioEngineAsset.mobilitySense
        case .safety: return StaticAudioEngineAsset.safetySense
        case .authoredActivity: return StaticAudioEngineAsset.tourPoiSense
        default: return StaticAudioEngineAsset.poiSense
        }
    }
    
}
