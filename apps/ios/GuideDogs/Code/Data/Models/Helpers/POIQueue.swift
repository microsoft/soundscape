//
//  POIQueue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class POIQueue {
    
    // MARK: Properties
    
    var pois: [POI] = []
    
    private let maxItems: Int
    private let sort: SortPredicate
    private let filter: FilterPredicate?

    // MARK: Initialization
    
    init(maxItems: Int, sort: SortPredicate, filter: FilterPredicate?) {
        guard maxItems > 0 else {
            fatalError("maxItems must be greater than zero")
        }
        
        self.maxItems = maxItems
        self.sort = sort
        self.filter = filter
    }
    
    // MARK: Manage Queue
    
    @inline(__always)
    private func findInsertionIndex(poi: POI) -> Int {
        var left = 0, right = pois.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            
            // If two POIs have the same distance and priority, the new POI will be
            // inserted after the existing POI (potentially non-deterministic in very rare cases).
            if sort.areInIncreasingOrder(poi, pois[mid]) == false {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        return left
    }
    
    func insert(_ poi: POI) {
        // Short-circuit the insertion index algorithm if we know this POI won't be inserted
        // POI does not pass filter
        if let filter = filter {
            guard filter.isIncluded(poi) else {
                return
            }
        }
        
        // Short-circuit the insertion index algorithm if we know this POI won't be inserted
        // Queue has reached max items
        guard pois.count != maxItems || sort.areInIncreasingOrder(poi, pois[maxItems - 1]) else {
            return
        }
        
        // Don't run binary search if the maxItems limit is only 1
        if maxItems == 1 {
            pois.insert(poi, at: 0)
            
            if pois.count > maxItems {
                pois.removeLast()
            }
            
            return
        }
        
        // Find the insertion index
        let i = findInsertionIndex(poi: poi)
        
        guard i >= 0 else {
            // Failed to find the insertion index
            return
        }
        
        // Insert the POI and trim the queue if need be
        pois.insert(poi, at: i)
        
        if pois.count > maxItems {
            pois.removeLast()
        }
    }
    
    func insert(_ pois: [POI]) {
        for poi in pois {
            insert(poi)
        }
    }
}
