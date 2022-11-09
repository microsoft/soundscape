//
//  MarkerQueue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class MarkerQueue {
    
    private typealias SortedMarker = (distance: CLLocationDistance, marker: ReferenceEntity)
    
    // MARK: Properties
    
    let maxItems: Int
    private let location: CLLocation
    private var sortedMarkers: [SortedMarker] = []
    
    var markers: [ReferenceEntity] {
        return sortedMarkers.map({ return $0.marker })
    }
    
    // MARK: Initialization
    
    init(maxItems max: Int, location userLocation: CLLocation, sortedItems: [ReferenceEntity] = []) {
        guard max > 0 else {
            fatalError("maxItems must be greater than zero")
        }
        
        maxItems = max
        location = userLocation
        sortedMarkers = sortedItems.map({ return (distance: $0.distanceToClosestLocation(from: userLocation), marker: $0) })
    }
    
    // MARK: Manage Queue
    
    @inline(__always)
    private func findInsertionIndex(marker: SortedMarker) -> Int {
        var left = 0, right = sortedMarkers.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            
            if marker.distance > sortedMarkers[mid].distance {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        return left
    }
    
    func insert(_ marker: ReferenceEntity) {
        let item = (distance: marker.distanceToClosestLocation(from: location), marker: marker)
        
        // Short-circuit the insertion index algorithm if we know this POI won't be inserted
        // Queue has reached max items
        guard sortedMarkers.count != maxItems || item.distance < sortedMarkers[maxItems - 1].distance else {
            return
        }
        
        // Don't run binary search if the maxItems limit is only 1
        if maxItems == 1 {
            sortedMarkers.insert(item, at: 0)
            
            if sortedMarkers.count > maxItems {
                sortedMarkers.removeLast()
            }
            
            return
        }
        
        // Find the insertion index
        let i = findInsertionIndex(marker: item)
        
        guard i >= 0 else {
            // Failed to find the insertion index
            return
        }
        
        // Insert the POI and trim the queue if need be
        sortedMarkers.insert(item, at: i)
        
        if sortedMarkers.count > maxItems {
            sortedMarkers.removeLast()
        }
    }
    
    func append(_ sortedMarkers: [ReferenceEntity]) {
        for marker in sortedMarkers {
            insert(marker)
        }
    }
}
