//
//  CalloutRangeContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// Used for representing distances at which we should detect or callout POIs for automatic callouts
enum CalloutRangeContext {
    
    /// Used in normal or walking scenarios
    case standard
    
    /// Used in automotive scenarios
    case automotive
    
    /// Used in Street Preview scenarios
    case streetPreview
    
    // MARK: Static properties
    
    private static let automotiveRangeMultiplier: CLLocationDistance = 6.0
    private static let streetPreviewRangeIncrement: CLLocationDistance = 10.0
    
    // MARK: Methods
    
    /// Distance to use when searching for POIs
    var searchDistance: CLLocationDistance {
        let searchDistance: CLLocationDistance = 50.0
        return transform(distance: searchDistance)
    }
    
    /// Distance to use when detecting POIs to call out
    func triggerRange(category: SuperCategory) -> CLLocationDistance {
        let triggerRange: CLLocationDistance
        
        switch category {
        case .objects, .safety:
            triggerRange = 10.0
        case .places, .information, .mobility, .authoredActivity:
            triggerRange = 20.0
        case .landmarks:
            triggerRange = 50.0
        default:
            triggerRange = 0.0
        }
        
        return transform(distance: triggerRange)
    }
    
    /// Distance to use when detecting if a POI is still in proximity after a callout
    func proximityRange(category: SuperCategory) -> CLLocationDistance {
        let proximityRange: CLLocationDistance
        
        switch category {
        case .objects, .safety:
            proximityRange = 20.0
        case .places, .information, .mobility, .authoredActivity:
            proximityRange = 30.0
        case .landmarks:
            proximityRange = 100.0
        default:
            proximityRange = 0.0
        }
        
        return transform(distance: proximityRange)
    }
    
    /// Transform the distance relative to the current activity
    private func transform(distance: CLLocationDistance) -> CLLocationDistance {
        switch self {
        case .standard:
            return distance
        case .automotive:
            return distance * CalloutRangeContext.automotiveRangeMultiplier
        case .streetPreview:
            return distance + CalloutRangeContext.streetPreviewRangeIncrement
        }
    }
    
}

extension SuperCategory {
    
    func triggerRange(context: CalloutRangeContext = .standard) -> CLLocationDistance {
        return context.triggerRange(category: self)
    }
    
    func proximityRange(context: CalloutRangeContext = .standard) -> CLLocationDistance {
        return context.proximityRange(category: self)
    }
    
}
