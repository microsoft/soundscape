//
//  IntersectionSearchResult.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import iOS_GPX_Framework

/// An object representing a result of an intersection search along a road at a specific coordinate
struct IntersectionSearchResult {
    
    /// The found intersection
    let intersection: Intersection
    
    /// The road to search on
    let road: Road
    
    /// The root coordinate to search from
    let rootCoordinate: CLLocationCoordinate2D
    
    /// Coordinates from the root coordinate to the found intersection
    let coordinatesToIntersection: [CLLocationCoordinate2D]
    
    /// The road bearing from root coordinate
    let bearing: CLLocationDirection
    
    let style: Intersection.Style
    
    init(intersection: Intersection,
         road: Road,
         rootCoordinate: CLLocationCoordinate2D,
         coordinatesToIntersection: [CLLocationCoordinate2D],
         style: Intersection.Style = .standard) {
        self.intersection = intersection
        self.road = road
        self.rootCoordinate = rootCoordinate
        self.coordinatesToIntersection = coordinatesToIntersection
        self.style = style
        
        self.bearing = GeometryUtils.pathBearing(for: self.coordinatesToIntersection,
                                                 maxDistance: GeometryUtils.maxRoadDistanceForBearingCalculation) ?? -1
    }
    
}
