//
//  IntersectionFinder.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// A helper to find nearby intersections
struct IntersectionFinder {
    
    // MARK: Properties
    
    /// The road to search on.
    let road: Road
    
    /// The origin coordinate on the road. Must be included in the `road` coordinates.
    let rootCoordinate: CLLocationCoordinate2D
    
    /// If `true`, will try to return the closest main intersections.
    /// Note that if no main intersections are found, regular intersections could be returned.
    let preferMainIntersections: Bool
    
    /// Use this property to determined which intersection types can be included in the result.
    let secondaryRoadsContext: SecondaryRoadsContext
    
    // MARK: Initialization
    
    /// This will return `nil` if the road coordinates does not contain the root coordinate.
    init?(rootCoordinate: CLLocationCoordinate2D,
          road: Road,
          preferMainIntersections: Bool = false,
          secondaryRoadsContext: SecondaryRoadsContext = .standard) {
        guard let roadCoordinates = road.coordinates, roadCoordinates.contains(rootCoordinate) else {
            return nil
        }
        
        self.rootCoordinate = rootCoordinate
        self.road = road
        self.preferMainIntersections = preferMainIntersections
        self.secondaryRoadsContext = secondaryRoadsContext
    }
    
    // MARK: Methods

    /// Returns the closest intersections to a coordinate on a road.
    ///
    /// Note that the coordinate can be the first, last or in-between coordinate on the road path.
    /// This can result in one of 3 options for the returned objects:
    /// ```
    /// // ⦿ coordinate
    /// // + intersection
    /// //                  →
    /// // Option 1: ⦿------------+ leading
    /// //                  ←
    /// // Option 2: +------------⦿ trailing
    /// //                  ←           →
    /// // Option 3: +------------⦿------------+ leading & trailing
    ///
    /// ```
    /// - Returns: Two optional intersections, leading and trailing for each direction of the coordinate.
    func closestIntersections() -> (leading: IntersectionSearchResult?, trailing: IntersectionSearchResult?) {
        // Search leading direction
        //                   direction →
        // +--------------⦿--------------+
        let leading = closestIntersection(fromCoordinate: rootCoordinate, onRoad: road)
        
        // Search trailing direction
        //   ← direction
        // +--------------⦿--------------+
        let trailing = closestIntersection(fromCoordinate: rootCoordinate, onRoad: road, reversedDirection: true)
        
        return (leading, trailing)
    }
    
    /// Returns the closest intersection to a coordinate on a road.
    ///
    /// - note:
    ///
    /// - Parameters:
    ///   - rootCoordinate: The origin coordinate on the road.
    ///   - road: The road to search on.
    ///   - trailingCoordinates: Pass any trailing coordinates that lead to the root coordinate.
    ///   In certain cases, we iterate recursively along road segments in order to find a main intersection.
    ///   While iterating, we need to collect all the coordinates leading up to the intersection.
    ///   When calling this method recursively on the next road segment, you can pass the trailing coordinates
    ///   to maintain the full coordinate path to the intersection.
    ///   - reversedDirection: If `true`, the search direction will be reversed.
    /// - Returns: The closest intersection on the road, if found.
    private func closestIntersection(fromCoordinate rootCoordinate: CLLocationCoordinate2D,
                                     onRoad road: Road,
                                     trailingCoordinates: [CLLocationCoordinate2D] = [],
                                     reversedDirection: Bool = false) -> IntersectionSearchResult? {
        guard let roadCoordinates = road.coordinates, !roadCoordinates.isEmpty else {
            return nil
        }
        
        let coordinatesFromRoot: [CLLocationCoordinate2D]
        
        if GeometryUtils.pathIsCircular(roadCoordinates) {
            // The road loops back to the root intersection
            // Example 1: https://www.openstreetmap.org/way/189315310
            // Example 2: https://www.openstreetmap.org/way/171693012
            coordinatesFromRoot = GeometryUtils.rotate(circularPath: roadCoordinates,
                                                       atCoordinate: rootCoordinate,
                                                       reversedDirection: reversedDirection)
        } else {
            coordinatesFromRoot = GeometryUtils.split(path: roadCoordinates,
                                                      atCoordinate: rootCoordinate,
                                                      reversedDirection: reversedDirection)
        }
        
        // Make sure the road sub coordinates contain more than the origin coordinate
        guard coordinatesFromRoot.count > 1 else {
            return nil
        }
        
        // Find all intersections (involving more than one road segment) along the road
        let intersections = road.intersections.filter { (intersection) -> Bool in
            let ids = intersection.roadIds.map { $0.id }
            return Set(ids).count > 1
        }
        
        guard !intersections.isEmpty else {
            return nil
        }
        
        let coordinatesFromRootExcludingRoot = Array(coordinatesFromRoot.dropFirst())
        
        if let firstIntersection = firstIntersection(alongRoadCoordinates: coordinatesFromRootExcludingRoot,
                                                     intersections: intersections) {
            // We found an intersection!
            let indexIncludingRootCoordinate = firstIntersection.index+1 // Account for the removed root coordinate
            let coordinatesToIntersection = Array(coordinatesFromRoot[...indexIncludingRootCoordinate])
            
            // Combine the trailing coordinates and the current coordinates
            // If there are no trailing coordinates, use the current coordinates
            // If there are trailing coordinates, combine and drop the first coordinate,
            // as it is the same as the last of the trailing coordinates.
            let combinedCoordinatesToIntersection = trailingCoordinates.isEmpty ?
                coordinatesToIntersection :
                (trailingCoordinates + coordinatesToIntersection.dropFirst())
            
            let intersection = firstIntersection.intersection
            
            let style: Intersection.Style
            if let roundabout = intersection.roundabout, !roundabout.isLarge {
                style = .roundabout
            } else if intersection.isMainIntersectionWithAClose(context: secondaryRoadsContext) {
                style = .circleDrive
            } else {
                style = .standard
            }
            
            return IntersectionSearchResult(intersection: intersection,
                                            road: road,
                                            rootCoordinate: rootCoordinate,
                                            coordinatesToIntersection: combinedCoordinatesToIntersection,
                                            style: style)
        }
        
        // Continue searching in adjacent road objects
        //
        // In OSM, some roads are represented as one 'Way' objects, others by a number of connected 'Way' objects.
        // For each 2 or more connected road segments, there should be an intersection object, 'main' or 'secondary'.
        // When trying to locate the closest main intersection along a road, we traverse the road coordinates to try and match a main intersection.
        // If this search fails to locate a main intersection, we continue traversing the next connected road until one is found or we reached a dead end.
        //
        // For example, we search for a main intersection along road A, segment 1.
        // We don't find a main intersection, but the last coordinate is a secondary intersection.
        // We retrieve road A, segment 2 and continue the search along that section, and so on.
        // Note: The direction of the road coordinates will not always continue in the direction we traverse, so we make sure to use the direction needed.
        //
        //         End of road A, segment 1
        //         Start of road A, segment 2        main
        //          Secondary intersection        intersection
        //                     ↓                       ↓
        // --------------------|----------------------------
        // ← A(1)              +              A(2) →   +
        // --------------------|----------------------------
        //
        
        guard let lastCoordinate = coordinatesFromRoot.last else {
            return nil
        }
        
        // Combine the trailing coordinates and the current coordinates
        // If there are no trailing coordinates, use the current coordinates
        // If there are trailing coordinates, combine and drop the first coordinate,
        // as it is the same as the last of the trailing coordinates.
        let combinedCoordinatesToIntersection = trailingCoordinates.isEmpty ?
            coordinatesFromRoot :
            (trailingCoordinates + coordinatesFromRoot.dropFirst())
        
        guard let endpointIntersection = intersections.first(where: { $0.coordinate == lastCoordinate }) else {
            // Reached the end of the road
            
            if road.intersections.contains(where: { $0.coordinate == lastCoordinate }) {
                // Don't synthesize an intersection here since we already filtered this intersection out
                return nil
            }
            
            // If the end of the road (last coordinate) does not have an associated intersection object
            // it indicates that there is no possibility to travel further.
            // In this case we return a synthesized intersection representing this endpoint.
            
            let intersection = Intersection()
            intersection.key = "-1"
            intersection.latitude = lastCoordinate.latitude
            intersection.longitude = lastCoordinate.longitude
            intersection.roadIds.append(IntersectionRoadId(withId: road.key))
            
            return IntersectionSearchResult(intersection: intersection,
                                            road: road,
                                            rootCoordinate: rootCoordinate,
                                            coordinatesToIntersection: combinedCoordinatesToIntersection,
                                            style: .roadEnd)
        }
        
        // Try to find the closest main intersection along the next road segment
        if let firstMainIntersection = closestMainIntersectionOnAdjacentRoad(forRoad: road,
                                                                             rootIntersection: endpointIntersection,
                                                                             trailingCoordinates: combinedCoordinatesToIntersection) {
            return firstMainIntersection
        }
        
        // If the next road segments does not contain a main intersection, try to return the last intersection.
        if let lastIntersection = lastIntersection(fromCoordinate: rootCoordinate,
                                                   onRoad: road,
                                                   trailingCoordinates: combinedCoordinatesToIntersection,
                                                   reversedDirection: reversedDirection) {
            return lastIntersection
        }
        
        return nil
    }
    
    /// Returns the closest main intersection on adjacent roads similar to `road`.
    ///
    /// Illustration:
    /// ```
    /// //         road   secondary intersection
    /// //          ↓      ↓
    /// //     +___________
    /// //     ↑           +
    /// //    root          \   ← same road, different sections
    /// // intersection      \    ↓
    /// //                    +___________+  ← closest main intersection
    /// ```
    ///
    /// - Parameters:
    ///   - road: The reference road.
    ///   - rootIntersection: The root intersection to search for adjacent roads.
    ///   - trailingCoordinates: Pass any trailing coordinates that lead to the root coordinate.
    ///   In certain cases, we iterate recursively along road segments in order to find a main intersection.
    ///   While iterating, we need to collect all the coordinates leading up to the intersection.
    ///   When calling this method recursively on the next road segment, you can pass the trailing coordinates
    ///   to maintain the full coordinate path to the intersection.
    /// - Returns: The closest main intersection on the road, if found.
    private func closestMainIntersectionOnAdjacentRoad(forRoad road: Road,
                                                       rootIntersection: Intersection,
                                                       trailingCoordinates: [CLLocationCoordinate2D] = []) -> IntersectionSearchResult? {
        let rootCoordinate = rootIntersection.coordinate
        
        let nextRoadSegments = road.nextRoadSegments(atIntersection: rootIntersection)
        
        guard nextRoadSegments.count < 2 else {
            // The `road` splits at `rootIntersection` to two or more seperate roads with the same name
            // Example: https://www.openstreetmap.org/node/539666019
            // In this case, mark `rootIntersection` as the target intersection.
            return IntersectionSearchResult(intersection: rootIntersection,
                                            road: road,
                                            rootCoordinate: rootCoordinate,
                                            coordinatesToIntersection: trailingCoordinates,
                                            style: .standard)
        }
        
        // Find the next adjacent road segment to `road`
        guard let nextRoadSegment = nextRoadSegments.first else {
            // Reached the end of the road
            return nil
        }
        
        guard let nextRoadSegmentCoordinates = nextRoadSegment.coordinates else {
            return nil
        }
        
        if GeometryUtils.pathIsCircular(nextRoadSegmentCoordinates) {
            return nil
        }
        
        if IntersectionFinder.roadContainsCycle(road: nextRoadSegment, to: trailingCoordinates) {
            return nil
        }
        
        // The adjacent road coordinates could be directing the opposite way
        // If so, reverse the direction of calculation
        // note: We want the first adjacent road coordinate to be the same as the last coordinate of the root road
        guard let lastAdjacentRoadCoordinate = nextRoadSegmentCoordinates.last else { return nil }
        let reversedDirection = (rootCoordinate == lastAdjacentRoadCoordinate)
        
        if let adjacentRoadClosestIntersection = closestIntersection(fromCoordinate: rootCoordinate,
                                                                     onRoad: nextRoadSegment,
                                                                     trailingCoordinates: trailingCoordinates,
                                                                     reversedDirection: reversedDirection) {
            return adjacentRoadClosestIntersection
        }
        
        return nil
    }
    
    /// Returns the first intersection along a road of coordinates, and it's index in the road coordinates.
    ///
    /// - Parameters:
    ///   - roadCoordinates: The road path.
    ///   - intersections: The intersections to search from.
    /// - Returns: The closest intersection on the path and it's coordinate index on the road path, if found.
    private func firstIntersection(alongRoadCoordinates roadCoordinates: [CLLocationCoordinate2D],
                                   intersections: [Intersection]) -> (intersection: Intersection, index: Int)? {
        guard !roadCoordinates.isEmpty else {
            return nil
        }
        
        var intersections = intersections
        
        if preferMainIntersections {
            // Filter out secondary intersections
            intersections.removeAll(where: { !$0.isMainIntersection(context: secondaryRoadsContext) })
        }
        
        guard !intersections.isEmpty else {
            return nil
        }
        
        for (i, coordinate) in roadCoordinates.enumerated() {
            if let intersection = intersections.first(where: { $0.coordinate == coordinate }) {
                let similarIntersectionWithMaxRoads = Intersection.similarIntersectionWithMaxRoads(intersection: intersection, intersections: intersections)
                return (similarIntersectionWithMaxRoads, i)
            }
        }
        
        return nil
    }
    
    private func lastIntersection(fromCoordinate rootCoordinate: CLLocationCoordinate2D,
                                  onRoad road: Road,
                                  trailingCoordinates: [CLLocationCoordinate2D] = [],
                                  reversedDirection: Bool = false) -> IntersectionSearchResult? {
        guard let roadCoordinates = road.coordinates, !roadCoordinates.isEmpty else {
            return nil
        }
        
        guard let lastCoordinate = reversedDirection ? roadCoordinates.first : roadCoordinates.last else {
            // Should not happen, road segments should have at least one coordinate.
            return nil
        }
        
        guard let intersection = road.intersection(atCoordinate: lastCoordinate) else {
            // Should not happen, road segments should always have an assigned intersection on edge/edges.
            return nil
        }
        
        let coordinatesToIntersection = GeometryUtils.split(path: roadCoordinates,
                                                            atCoordinate: rootCoordinate,
                                                            reversedDirection: reversedDirection)
        
        // Combine the trailing coordinates and the current coordinates
        // If there are no trailing coordinates, use the current coordinates
        // If there are trailing coordinates, combine and drop the first coordinate,
        // as it is the same as the last of the trailing coordinates.
        let combinedCoordinatesToIntersection = trailingCoordinates.isEmpty ?
            coordinatesToIntersection :
            (trailingCoordinates + coordinatesToIntersection.dropFirst())
        
        guard let nextRoadSegment = road.nextRoadSegments(atIntersection: intersection).first else {
            // Reached the end of the road
            return IntersectionSearchResult(intersection: intersection,
                                            road: road,
                                            rootCoordinate: rootCoordinate,
                                            coordinatesToIntersection: combinedCoordinatesToIntersection,
                                            style: .roadEnd)
        }
        
        guard let nextRoadSegmentCoordinates = nextRoadSegment.coordinates else { return nil }

        if GeometryUtils.pathIsCircular(nextRoadSegmentCoordinates) {
             return IntersectionSearchResult(intersection: intersection,
                                             road: road,
                                             rootCoordinate: rootCoordinate,
                                             coordinatesToIntersection: combinedCoordinatesToIntersection,
                                             style: .circleDrive)
         }
        
        if IntersectionFinder.roadContainsCycle(road: nextRoadSegment, to: trailingCoordinates) {
            if intersection.coordinate == self.rootCoordinate {
                // If the road loops back to the root coordinate, no need to return an intersection.
                return nil
            } else {
                // If the road loops back to any other coordinate on the path, return the intersection at the end of the road.
                return IntersectionSearchResult(intersection: intersection,
                                                road: road,
                                                rootCoordinate: rootCoordinate,
                                                coordinatesToIntersection: combinedCoordinatesToIntersection,
                                                style: .standard)
            }
        }
        
        // The next road segment's coordinates could be directing the opposite way
        // If so, reverse the direction of calculation
        // note: We want the first adjacent road coordinate to be the same as the last coordinate of the root road
        guard let lastAdjacentRoadCoordinate = nextRoadSegmentCoordinates.last else { return nil }
        let reversedDirection = (lastCoordinate == lastAdjacentRoadCoordinate)
        
        return lastIntersection(fromCoordinate: lastCoordinate,
                                onRoad: nextRoadSegment,
                                trailingCoordinates: combinedCoordinatesToIntersection,
                                reversedDirection: reversedDirection)
    }
    
    /// Returns `true` if the road start or end coordinate contain the last coordinate in `coordinates`.
    /// Used to detect loops between next segments on roads.
    ///
    /// - example: Heading west on [Phyllis Court Drive](https://www.openstreetmap.org/way/43077629) from this [coordinate](https://www.openstreetmap.org/node/539665990).
    /// Then heading east from this [coordinate](https://www.openstreetmap.org/node/539666019) on [Phyllis Court Drive](https://www.openstreetmap.org/way/43077631).
    private static func roadContainsCycle(road: Road, to coordinates: [CLLocationCoordinate2D]) -> Bool {
        guard let roadCoordinates = road.coordinates else { return false }
        guard let lastCoordinate = coordinates.last else { return false }
        
        if roadCoordinates.first == lastCoordinate && roadCoordinates.last == lastCoordinate {
            // The road starts and ends at the same coordinate (loops back)
            return true
        }
        
        // Check if any road coordinate (excluding the root coordinate) loops back to a
        // point along the trailing coordinates.
        var coordinatesExcludingRoot: [CLLocationCoordinate2D]
        
        // Because of road segments direction, we check if the root coordinate is the first or last.
        if roadCoordinates.first == lastCoordinate {
            coordinatesExcludingRoot = Array(roadCoordinates.dropFirst())
        } else if roadCoordinates.last == lastCoordinate {
            coordinatesExcludingRoot = roadCoordinates.dropLast()
        } else {
            return false
        }
        
        if coordinatesExcludingRoot.contains(where: { coordinates.contains($0) }) {
            return true
        }
        
        return false
    }
    
}
