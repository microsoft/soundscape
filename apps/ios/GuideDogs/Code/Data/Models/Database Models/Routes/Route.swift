//
//  Route.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import RealmSwift
import CoreLocation

extension Notification.Name {
    static let routeAdded = Notification.Name("GDARouteAdded")
    static let routeUpdated = Notification.Name("GDARouteUpdated")
    static let routeDeleted = Notification.Name("GDARouteDeleted")
}

/*
 A route is an ordered collection of markers. Additional metadata for
 routes include name, description and various properties which track
 route usage (e.g., `createdDate`, `lastUpdatedDate`, `lastSelectedDate`)
 */
class Route: Object, ObjectKeyIdentifiable {
    
    // MARK: Constants
    
    struct Keys {
        static let id = "GDARouteID"
    }
    
    // MARK: Properties
    
    // Primary Key
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String
    // `description` is a `RLMObject` property so prepending `route` to
    // property name
    @Persisted var routeDescription: String?
    @Persisted var waypoints: List<RouteWaypoint>
    // Save the location of the first waypoint to support fast queries
    // for nearby routes
    @Persisted var firstWaypointLatitude: CLLocationDegrees?
    @Persisted var firstWaypointLongitude: CLLocationDegrees?
    @Persisted var isNew: Bool = true
    @Persisted var createdDate: Date = Date()
    @Persisted var lastUpdatedDate: Date = Date()
    // `lastSelectedDate` is updated when the user selects an action
    // (`RouteAction` - start, share, etc.) for the route
    @Persisted var lastSelectedDate: Date = Date()
    
    var firstWaypointLocation: CLLocation? {
        guard let latitude = firstWaypointLatitude, let longitude = firstWaypointLongitude else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        guard coordinate.isValidLocationCoordinate else {
            return nil
        }
        
        return CLLocation(coordinate)
    }
    
    var isActive: Bool {
        guard let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            return false
        }
        
        guard case let .database(activeID) = routeGuidance.content.source else {
            return false
        }
        
        return activeID == self.id
    }
    
    // MARK: Initialization
    
    /**
     * Initializes a route for which all associated markers have been added to the Realm database
     *
     * - Parameters:
     *     - name: Name of the route, required
     *     - description: Description of the route, optional
     *     - waypoints: Array of waypoints - All waypoints are markers that exist in the Realm databse
     */
    convenience init(name: String, description: String?, waypoints: [RouteWaypoint]) {
        self.init()
        
        self.name = name
        self.routeDescription = description
        
        // Append waypoints
        waypoints.forEach({ self.waypoints.append($0) })
        
        if let first = waypoints.ordered.first, let marker = first.asLocationDetail {
            firstWaypointLatitude = marker.location.coordinate.latitude
            firstWaypointLongitude = marker.location.coordinate.longitude
        }
    }
    
    /**
     Only use this initializer when you made sure all the route waypoints (marker)
     were already imported to the database.
     */
    convenience init(from parameters: RouteParameters) {
        self.init()
        
        // Required Parameters
        
        id = parameters.id
        name = parameters.name
        routeDescription = parameters.routeDescription
        
        // Append waypoints
        let pWaypoints = parameters.waypoints.compactMap({ return RouteWaypoint(from: $0) })
        waypoints.append(objectsIn: pWaypoints)
        
        if let first = pWaypoints.ordered.first, let marker = SpatialDataCache.referenceEntityByKey(first.markerId) {
            firstWaypointLatitude = marker.latitude
            firstWaypointLongitude = marker.longitude
        }
        
        // Optional Parameters
        
        if let pCreatedDate = parameters.createdDate {
            createdDate = pCreatedDate
        }
        
        if let pLastUpdatedDate = parameters.lastUpdatedDate {
            lastUpdatedDate = pLastUpdatedDate
        }
        
        if let pLastSelectedDate = parameters.lastSelectedDate {
            lastSelectedDate = pLastSelectedDate
        }
    }
    
}
