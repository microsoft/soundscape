//
//  RouteWaypointParameters.swift
//  SoundscapeUnitTests
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/*
 Supports serialization of the Realm `RouteWaypoint` object
 */
struct RouteWaypointParameters: Codable {
    
    // MARK: Properties
    
    let index: Int
    let markerId: String
    // Marker parameters will be included when sharing routes via
    // custom document type but will not be stored in iCloud because all markers
    // are serialized and stored separately in iCloud
    let marker: MarkerParameters?
    
    // MARK: Initialization
    
    init(index: Int, markerId: String, marker: MarkerParameters?) {
        self.index = index
        self.markerId = markerId
        self.marker = marker
    }
    
    init(waypoint: RouteWaypoint) {
        let index = waypoint.index
        let markerId = waypoint.markerId
        let marker = MarkerParameters(markerId: markerId)
        
        self.init(index: index, markerId: markerId, marker: marker)
    }
    
}
