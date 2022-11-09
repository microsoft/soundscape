//
//  Array+POI.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Array where Element == POI {
    
    typealias Quadrant = [CompassDirection: [POI]]
    
    func sorted(by sortPredicate: SortPredicate, filteredBy filterPredicate: FilterPredicate? = nil, maxLength: Int) -> [POI] {
        let queue = POIQueue(maxItems: maxLength, sort: sortPredicate, filter: filterPredicate)
        // Sort and filter all elements in `self`
        queue.insert(self)
        return queue.pois
    }
    
    func filtered(by filterPredicate: FilterPredicate, maxLength: Int? = nil) -> [POI] {
        var pois: [POI] = []
        
        for poi in self {
            if let maxLength = maxLength {
                guard pois.count < maxLength else {
                    // Reached maximum length
                    // Return POI array
                    return pois
                }
            }
            
            guard filterPredicate.isIncluded(poi) else {
                continue
            }
            
            pois.append(poi)
        }
        
        return pois
    }
    
    func quadrants(_ includedQuadrants: [CompassDirection] = CompassDirection.allDirections, location: CLLocation, heading: CLLocationDirection, categories: [SuperCategory], maxLengthPerQuadrant: Int) -> Quadrant {
        // Calculate range for each quadrant given heading
        let quadrants = SpatialDataView.getQuadrants(heading: heading)
        let sortPredicate = Sort.distance(origin: location)
        let categoryFilterPredicate = Filter.superCategories(orExpected: categories)
        
        // After sorting by distance and filtering by super category, we will filter once
        // more to remove any POIs that contain the given location
        // In case additional POIs are filtered by location, increase the maximum length during this pass
        
        let queues: [CompassDirection: POIQueue] = includedQuadrants.reduce(into: [:]) { dict, direction in
            dict[direction] = POIQueue(maxItems: maxLengthPerQuadrant + 10, sort: sortPredicate, filter: categoryFilterPredicate)
        }
        
        for poi in self {
            let dir = CompassDirection.from(bearing: poi.bearingToClosestLocation(from: location), quadrants: quadrants)
            queues[dir]?.insert(poi)
        }
        
        let locationFilterPredicate = Filter.location(expected: location).invert()
        
        // Remove POIs that contain the given location
        // Only filter by location after reducing the size of the array in the initial
        // sort and filter pass
        return queues.reduce(into: [:]) { partialResult, kvp in
            partialResult[kvp.key] = kvp.value.pois.filtered(by: locationFilterPredicate, maxLength: maxLengthPerQuadrant)
        }
    }
    
}
