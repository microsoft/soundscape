//
//  Array+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

extension Array where Element: Hashable {
    /// Converts an array of hashable elements to a set
    ///
    /// - Returns: A Set built from the contents of the array
    func toSet() -> Set<Element> {
        return Set(self)
    }
}

extension Array where Element: Hashable {
    func dropDuplicates() -> [Element] {
        var array = [Element]()
        var set = Set<Element>()
        
        for element in self where set.insert(element).inserted {
            array.append(element)
        }
        
        return array
    }
}

extension Array where Element == ReferenceEntity {
    private struct SortedEntity {
        let entity: ReferenceEntity
        let distance: CLLocationDistance
        
        init(_ refEntity: ReferenceEntity, _ dist: CLLocationDistance) {
            entity = refEntity
            distance = dist
        }
    }
    
    /// Sorts markers using a single `MarkerQueue` and the user's location. Markers are
    /// sorted by distance from the user.
    ///
    /// - Parameters:
    ///   - maxItems: Maximum number of items to be returned
    ///   - location: User's location
    /// - Returns: Sorted array of markers
    func sort(maxItems: Int, location: CLLocation) -> [ReferenceEntity] {
        let queue = MarkerQueue(maxItems: maxItems, location: location)
        // Sort all elements in `self`
        queue.append(self)
        return queue.markers
    }
    
    func selectNearestInEachQuadrant(location: CLLocation,
                                     heading: CLLocationDirection,
                                     maxDistance range: CLLocationDistance? = nil,
                                     excludeEntitiesContainingLocation excluding: Bool = true) -> [CompassDirection: ReferenceEntity] {
        // Get the quadrants (based on the user's current heading) used for grouping POIs
        let quadrants = SpatialDataView.getQuadrants(heading: heading)
        
        var north: SortedEntity?
        var east: SortedEntity?
        var south: SortedEntity?
        var west: SortedEntity?
        
        for entity in self {
            let dist = entity.distanceToClosestLocation(from: location)
            
            switch CompassDirection.from(bearing: entity.bearingToClosestLocation(from: location), quadrants: quadrants) {
            case .north:
                if north == nil || dist < north!.distance,
                    !excluding || !entity.getPOI().contains(location: location.coordinate) {
                    north = SortedEntity(entity, dist)
                }
            case .east:
                if east == nil || dist < east!.distance,
                    !excluding || !entity.getPOI().contains(location: location.coordinate) {
                    east = SortedEntity(entity, dist)
                }
            case .south:
                if south == nil || dist < south!.distance,
                    !excluding || !entity.getPOI().contains(location: location.coordinate) {
                    south = SortedEntity(entity, dist)
                }
            case .west:
                if west == nil || dist < west!.distance,
                    !excluding || !entity.getPOI().contains(location: location.coordinate) {
                    west = SortedEntity(entity, dist)
                }
            case .unknown:
                break
            }
        }
        
        var results: [CompassDirection: ReferenceEntity] = [:]
        
        if let north = north?.entity {
            results[.north] = north
        }
        
        if let east = east?.entity {
            results[.east] = east
        }
        
        if let south = south?.entity {
            results[.south] = south
        }
        
        if let west = west?.entity {
            results[.west] = west
        }
        
        return results
    }
}

extension Array where Element == AnyCancellable {
    
    mutating func cancelAndRemoveAll() {
        forEach({ $0.cancel() })
        removeAll()
    }
    
}
