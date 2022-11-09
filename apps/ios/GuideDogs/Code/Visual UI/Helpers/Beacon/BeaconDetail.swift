//
//  BeaconDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct BeaconDetail {
    
    // MARK: Parameters
    
    let locationDetail: LocationDetail
    var isAudioEnabled: Bool
    let routeDetail: RouteDetail?
    
    // MARK: Initialization
    
    /*
     * Default initializer
     *
     * This initializer is private and only used by by struct methods
     */
    private init(locationDetail: LocationDetail, isAudioEnabled: Bool, routeDetail: RouteDetail?) {
        self.locationDetail = locationDetail
        self.isAudioEnabled = isAudioEnabled
        self.routeDetail = routeDetail
    }
    
    /*
     * Create `BeaconDetail` for a beacon placed on the given location.
     * This initializer is used when the beacon does not belong to a route.
     *
     * Parameters
     * - locationDetail is location of the audio beacon
     * - isAudioEnabled true if beacon audio is currently enabled
     */
    init(locationDetail: LocationDetail, isAudioEnabled: Bool) {
        self.locationDetail = locationDetail
        self.isAudioEnabled = isAudioEnabled
        // Audio beacon is set on a single location
        self.routeDetail = nil
    }
    
    /*
     * Create `BeaconDetail` for a beacon that belongs to a route
     *
     * If the route is not active or there is no current waypoint,
     * return `nil`
     *
     * Parameters
     * - route is route to which the beacon belongs
     * - isAudioEnabled true if beacon audio is currently enabled
     */
    init?(from route: RouteGuidance, isAudioEnabled: Bool) {
        guard let waypoint = route.currentWaypoint?.waypoint else {
            return nil
        }
        
        self.locationDetail = waypoint
        self.isAudioEnabled = isAudioEnabled
        self.routeDetail = route.content
    }
    
    /*
     * Static initializer
     *
     * Updates `locationDetail` properties and preserves other property
     * values (e.g., `isAudioEnabled`, `route`)
     *
     * Parmater - value is the `BeaconDetail` value to update
     *
     * Returns a new value for `BeaconDetail` with the updated `locationDetail`
     * property
     *
     */
    static func updateLocationDetailIfNeeded(for value: BeaconDetail) -> BeaconDetail {
        let newValue = LocationDetail.updateLocationIfNeeded(for: value.locationDetail)
        return BeaconDetail(locationDetail: newValue, isAudioEnabled: value.isAudioEnabled, routeDetail: value.routeDetail)
    }
    
}

extension BeaconDetail {
    
    var toMapStyle: MapStyle {
        if let routeDetail = routeDetail {
            return .route(detail: routeDetail)
        } else {
            return .location(detail: locationDetail)
        }
    }
    
}
