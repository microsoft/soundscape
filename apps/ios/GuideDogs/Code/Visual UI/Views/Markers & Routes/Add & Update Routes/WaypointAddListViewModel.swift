//
//  WaypointAddListViewModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import Combine

class WaypointAddListViewModel: ObservableObject {
    
    // MARK: Properties
    
    @Published private(set) var markers: [IdentifiableLocationDetail] = []
    @Binding private var waypoints: [IdentifiableLocationDetail]
    
    let markerStore = MarkerLoader()
    private var listeners: [AnyCancellable] = []
    
    // MARK: Initialization
    
    init(waypoints: Binding<[IdentifiableLocationDetail]>) {
        _waypoints = waypoints
        
        listeners.append(markerStore.$markerIDs
                            .receive(on: RunLoop.main)
                            .sink(receiveValue: { [weak self] newValue in
                                guard let `self` = self else {
                                    return
                                }
                                
                                self.onMarkersDidChange(newMarkerIds: newValue)
                                
                                self.objectWillChange.send()
                            }))
        
        markerStore.load(sort: .distance)
    }
    
    private func onMarkersDidChange(newMarkerIds: [String]) {
        markers = newMarkerIds
            .compactMap({ markerId in
                // If the marker is an existing waypoint, update the index
                let index = waypoints.firstIndex(where: { $0.locationDetail.markerId == markerId })
                
                // If the marker is an existing waypoint, return it
                if let value = waypoints.first(where: { $0.locationDetail.markerId == markerId }) {
                    value.index = index
                    return value
                }
                
                guard let detail = LocationDetail(markerId: markerId) else {
                    return nil
                }
                
                // Create a new element and add it to the marker list
                return IdentifiableLocationDetail(locationDetail: detail, index: index)
            })
    }
    
    // MARK: Manage Waypoints
    
    func addWaypoint(_ element: IdentifiableLocationDetail) {
        guard waypoints.contains(where: { return $0.id == element.id }) == false else {
            // Element is already a waypoint
            return
        }
        
        GDATelemetry.track("waypoint.add")
        
        // Add to waypoint list
        waypoints.append(element)
        
        // Add waypoint index
        element.index = waypoints.count - 1
        
        self.objectWillChange.send()
    }
    
    func removeWaypoint(at index: Int) {
        guard index >= 0, index < waypoints.count else {
            // Invalid index
            return
        }
        
        GDATelemetry.track("waypoint.remove")
        
        // Remove from waypoint list
        let element = waypoints.remove(at: index)
        
        // Remove waypoint index
        element.index = nil
        
        // Update the remaining waypoint indices
        waypoints.forEach({
            if let i = $0.index, i > index {
                $0.index = i - 1
            }
        })
        
        self.objectWillChange.send()
    }
    
}
