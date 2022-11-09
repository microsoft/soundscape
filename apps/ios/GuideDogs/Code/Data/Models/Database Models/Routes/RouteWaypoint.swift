//
//  RouteWaypoint.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import RealmSwift

/*
 Represents the waypoints belonging to a route.
 
 Each waypoint in the `Route` object is represented by
 an existing `ReferenceEntity` (e.g., `markerId`) and an
 index that reflects the waypoint's ordering within the
 route.
 */
class RouteWaypoint: EmbeddedObject {
    
    typealias Completion = (Result<RouteWaypoint, Error>) -> Void
    
    // MARK: Properties
    
    // Represents the order that this waypoint will appear
    // in the `Route` object
    @Persisted var index: Int = -1
    // `markerId` is the primary key for a `ReferenceEntity`
    // object
    @Persisted var markerId: String = ""
    // Use `locationDetail` to persist waypoint and marker data that is
    // being imported from a URL resource and has not been added to the
    // Realm database (e.g., sharing activity)
    private var importedLocationDetail: LocationDetail?
    
    // This value should never be `nil`
    var asLocationDetail: LocationDetail? {
        // If there is imported data, return it
        // Otherwise, return Realm data
        return importedLocationDetail ?? LocationDetail(markerId: markerId)
    }
    
    // MARK: Initialization
    
    /**
     * Initializes a waypoint from a marker that exists in the Realm database.
     *
     * - Parameters:
     *     - index: Index of the waypoint
     *     - markerId: ID for a marker that exists in Realm database
     */
    convenience init?(index: Int, markerId: String) {
        self.init()
        
        guard LocationDetail(markerId: markerId) != nil else {
            // Marker does not exist
            return nil
        }
        
        self.index = index
        self.markerId = markerId
        self.importedLocationDetail = nil
    }
    
    /**
     * Initializes a waypoint from a marker that exists in the Realm database.
     *
     * - Parameters:
     *     - index: Index of the waypoint
     *     - locationDetail: Data for a marker that exists in Realm database
     */
    convenience init?(index: Int, locationDetail: LocationDetail) {
        self.init()
        
        guard let markerId = locationDetail.markerId else {
            // Location is not a marker
            return nil
        }
        
        self.index = index
        self.markerId = markerId
        self.importedLocationDetail = nil
    }
    
    /**
     * Initializes a waypoint from a marker that is being imported from a URL resource (e.g.,
     * sharing activity) and has not been added to the Realm database.
     *
     * Initializer should only be called after fetching the associated marker data via `RouteParametersHandler`!
     *
     * - Parameters:
     *     - index: Index of the waypoint
     *     - markerId: ID for imported marker
     *     - importedLocationDetail: Data for marker that is being imported
     */
    convenience init(index: Int, markerId: String, importedLocationDetail: LocationDetail) {
        self.init()
        
        self.index = index
        self.markerId = markerId
        self.importedLocationDetail = importedLocationDetail
    }
    
    convenience init(from parameters: RouteWaypointParameters) {
        self.init()
        
        index = parameters.index
        markerId = parameters.markerId
    }
    
}

extension List where Element == RouteWaypoint {
    
    var ordered: [RouteWaypoint] {
        return self.sorted(by: { return $0.index < $1.index })
    }
    
}

extension Array where Element == RouteWaypoint {
    
    var ordered: [RouteWaypoint] {
        return self.sorted(by: { return $0.index < $1.index })
    }
    
    var asLocationDetail: [LocationDetail] {
        return self.compactMap({ return $0.asLocationDetail })
    }
    
}
