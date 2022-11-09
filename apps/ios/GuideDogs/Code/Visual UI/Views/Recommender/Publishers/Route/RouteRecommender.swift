//
//  RouteRecommender.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine
import SwiftUI
import CoreLocation

/*
 * This recommender listens for location updates and queries for nearby routes.
 * If there is a route nearby the given location, the recommender publishes a corresponding
 * `RouteRecommenderView`, else the recommender publishes a `nil` value.
 *
 */
class RouteRecommender: Recommender {
    
    // Properties
    
    let publisher: CurrentValueSubject<(() -> AnyView)?, Never> = .init(nil)
    private var listeners: [AnyCancellable] = []
    
    // MARK: Initialization
    
    init() {
        self.publishCurrentValue()
        
        listeners.append(NotificationCenter.default.publisher(for: .locationUpdated)
                            // Location updates occur more frequently than required by the recommender
                            // Throttle updates to once every 15.0 seconds
                            .throttle(for: 15.0, scheduler: RunLoop.main, latest: true)
                            .receive(on: RunLoop.main)
                            .sink(receiveValue: { [weak self] _ in
                                guard let `self` = self else {
                                    return
                                }
                                
                                self.publishCurrentValue()
                            }))
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
    // MARK: Manage Publisher
    
    private func publishCurrentValue() {
        var currentValue: (() -> AnyView)?
        
        defer {
            // Publish the current value
            self.publisher.value = currentValue
        }
        
        guard let location = AppContext.shared.geolocationManager.location else {
            // Location is unknown
            return
        }
        
        // Search for routes near the given location and sort
        // by `lastSelectedDate`
        let nearby = SpatialDataCache.routesNear(location.coordinate, range: 5000)
            .compactMap({ route -> (route: Route, distance: CLLocationDistance, selected: Date, created: Date)? in
                // Because these routes were returned by `SpatialDataCache.routesNear`, the first waypoint location
                // should never be `nil`
                guard let wLocation = route.firstWaypointLocation else {
                    return nil
                }
                
                return (route: route, distance: location.distance(from: wLocation), selected: route.lastSelectedDate, created: route.createdDate)
            })
            .sorted(by: {
                if $0.distance != $1.distance {
                    // Sort by distance to user's current location
                    return $0.distance < $1.distance
                }
                
                if $0.selected != $1.selected {
                    // Sort by most recently selected
                    return $0.selected > $1.selected
                }
                
                // Finally, sort by most recently created
                return $0.created > $1.created
            })
            .compactMap({ return $0.route })
        
        guard let first = nearby.first else {
            // There are no nearby routes
            return
        }
        
        let detail = RouteDetail(source: .database(id: first.id))
        
        // Update the current value
        currentValue = {
            AnyView(RouteRecommenderView(route: detail))
        }
    }
    
}
