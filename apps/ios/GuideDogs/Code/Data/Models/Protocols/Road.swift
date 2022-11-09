//
//  Road.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol Road: POI {
    
    var roundabout: Bool { get set }
    
}

// MARK: - Main Road Detection Type

enum MainRoadDetectionType {
    /// Detect a main road by its name
    case roadName
    
    /// Detect a main road by its type
    case roadType
}

// MARK: - Road Direction at Intersection

private enum RoadDirectionAtIntersection {
    /// The road is leading up to an intersection
    ///        →
    /// --------------⦿
    case leading
    
    /// The road continues on from an intersection
    ///        →
    /// ⦿--------------
    case trailing
    
    /// The road is leading up to and continues on from an intersection
    ///    →       →
    /// -------⦿-------
    case leadingAndTrailing
    
    /// The road does not contain the intersection
    case none
}

// MARK: - Bearing

extension Road {
    
    /// Calculates the road bearing.
    ///
    /// Illustration:
    /// ```
    /// //          / B  /  - Reference road coordinate
    /// //         / ↗︎  /   - Bearing from A to B
    /// // -------     /
    /// // A          /     - First road coordinate
    /// // ----------
    /// ```
    ///
    /// - Parameters:
    ///   - maxRoadDistance: The max distance for the reference coordinate.
    ///   - reversedDirection: If set to `true`, the bearing will be calculated for the reverse road path.
    /// - Returns: The bearing from the first coordinate on the road path to another reference
    /// coordinate along the path, cauclualted with the `maxRoadDistance` value.
    func bearing(maxRoadDistance: CLLocationDistance = GeometryUtils.maxRoadDistanceForBearingCalculation,
                 reversedDirection: Bool = false) -> CLLocationDirection? {
        guard let coordinates = self.coordinates, !coordinates.isEmpty else { return nil }
        
        return GeometryUtils.pathBearing(for: reversedDirection ? coordinates.reversed() : coordinates,
                                         maxDistance: maxRoadDistance)
    }
    
}

// MARK: - Road Helper

extension Road {
    
    /// Road type (via Soundscape custom tag), such as "walking_path", "service_road", "road", etc.
    var type: String {
        guard let osmObject = self as? GDASpatialDataResultEntity else { return "road" }
        return osmObject.nameTag
    }
    
    var coordinates: [CLLocationCoordinate2D]? {
        guard let osmEntity = self as? GDASpatialDataResultEntity else { return nil }
        guard let points = osmEntity.coordinates as? GALine else { return nil }
        return points.toCoordinates()
    }
    
    var intersections: [Intersection] {
        return SpatialDataCache.intersections(forRoadKey: key) ?? []
    }
    
    func intersection(atCoordinate coordinate: CLLocationCoordinate2D) -> Intersection? {
        return SpatialDataCache.intersection(forRoadKey: key, atCoordinate: coordinate)
    }
    
    func isMainRoad(context: SecondaryRoadsContext = .standard, detectionType: MainRoadDetectionType = .roadName) -> Bool {
        switch detectionType {
        case .roadName:
            // If the road has a given name, it is a main road.
            if !name.isEmpty {
                return true
            }
            
            // Make sure the road's synthesized name is not included in the secondary roads list
            let secondaryRoadNames = context.localizedSecondaryRoadNames.map({ $0.lowercasedWithAppLocale() })
            return !secondaryRoadNames.contains(localizedName.lowercasedWithAppLocale())
        case .roadType:
            return !context.secondaryRoadTypes.contains(self.type)
        }
    }
    
    /// In OSM, roads can be split to multiple segments. These segments are connected by intersection objects synthesized by Soundscape.
    ///
    /// This returns the next road segments for a road at an intersection.
    /// - note: Roads can split into multiple road segments, such as this [OSM node](https://www.openstreetmap.org/node/539666019).
    func nextRoadSegments(atIntersection intersection: Intersection) -> [Road] {
        let roadDirection = self.direction(at: intersection)
        
        return intersection.roads
            // Look for roads with the same name
            .filter { $0.key != self.key && $0.name == self.name }
            .sorted { (road1, road2) -> Bool in
                // Prefer roads with the same type
                if road1.type == self.type && road2.type != self.type {
                    return true
                }
                
                // Prefer roads that are in the same direction as the given road
                //
                // Road A(1) is leading towards the intersection:
                //
                //     Road A(1)      Road A(2)
                // +--------------⦿--------------+
                //         →             →
                //
                // Road A(1) continues on from the intersection:
                //
                //     Road A(1)      Road A(2)
                // +--------------⦿--------------+
                //        ←              ←
                
                let road1Direction = road1.direction(at: intersection)
                let road2Direction = road1.direction(at: intersection)
                
                if (roadDirection == .trailing && road1Direction == .leading && road2Direction != .leading) ||
                    (roadDirection == .leading && road1Direction == .trailing && road2Direction != .trailing) {
                    return true
                }
                
                return false
        }
        
    }
    
    /// Returns the road direction type at an intersection
    private func direction(at intersection: Intersection) -> RoadDirectionAtIntersection {
        guard let roadCoordinates = coordinates else { return .none }
        let intersectionCoordinate = intersection.coordinate
        
        if intersectionCoordinate == roadCoordinates.first {
            return .leading
        } else if intersectionCoordinate == roadCoordinates.last {
            return .trailing
        } else if roadCoordinates.contains(intersectionCoordinate) {
            return .leadingAndTrailing
        }
        
        return .none
    }
    
}
