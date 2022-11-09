//
//  BeaconStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum BeaconStyle {
    case location(detail: LocationDetail)
    case route(behavior: RouteGuidance)
    case tour(behavior: GuidedTour)
}

extension BeaconStyle {
    
    var mapStyle: MapStyle {
        switch self {
        case .location(let detail): return .location(detail: detail)
        case .route(let behavior): return .route(detail: behavior.content)
        case .tour(let behavior): return .tour(detail: behavior.content)
        }
    }
    
}
