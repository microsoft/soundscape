//
//  MapStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum MapStyle {
    case location(detail: LocationDetail)
    case waypoint(detail: WaypointDetail)
    case route(detail: RouteDetail)
    case tour(detail: TourDetail)
}

extension MapStyle {
    
    var description: String {
        switch self {
        case .location: return "location"
        case .waypoint: return "waypoint"
        case .route: return "route"
        case .tour: return "tour"
        }
    }
    
}
