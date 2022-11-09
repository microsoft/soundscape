//
//  RouteParamters.swift
//  SoundscapeUnitTests
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/*
 Supports serialization of the Realm `Route` object
 */
struct RouteParameters: Codable {
    
    enum Context {
        case backup
        case share
    }
    
    // MARK: Properties
    
    let id: String
    let name: String
    let routeDescription: String?
    let waypoints: [RouteWaypointParameters]
    // `createdDate`, `lastUpdatedDate` and `lastSelectedDate` will be serialized and stored in iCloud but will not
    // be included when sharing routes via custom document type
    let createdDate: Date?
    let lastUpdatedDate: Date?
    let lastSelectedDate: Date?
    
    // MARK: Initialization
    
    init(id: String, name: String, routeDescription: String?, waypoints: [RouteWaypointParameters], createdDate: Date?, lastUpdatedDate: Date?, lastSelectedDate: Date?) {
        self.id = id
        self.name = name
        self.routeDescription = routeDescription
        self.waypoints = waypoints
        self.createdDate = createdDate
        self.lastUpdatedDate = lastUpdatedDate
        self.lastSelectedDate = lastSelectedDate
    }
    
    init?(route: Route, context: Context) {
        let id = route.id
        let name = route.name
        let routeDescription = route.routeDescription
        let waypoints = Array(route.waypoints).compactMap({ return RouteWaypointParameters(waypoint: $0) })
        // Ignore `createdDate`, `lastUpdatedDate` and `lastSelectedDate` unless encoding data for iCloud backup
        let createdDate = context == .backup ? route.createdDate : nil
        let lastUpdatedDate = context == .backup ? route.lastUpdatedDate : nil
        let lastSelectedDate = context == .backup ? route.lastSelectedDate : nil
        
        // When decoding a route from a URL resource (e.g., `context == .share`),
        // all waypoints should include marker data
        guard context == .backup || waypoints.contains(where: { $0.marker == nil }) == false else {
            return nil
        }
        
        self.init(id: id, name: name, routeDescription: routeDescription, waypoints: waypoints, createdDate: createdDate, lastUpdatedDate: lastUpdatedDate, lastSelectedDate: lastSelectedDate)
    }
    
}
