//
//  Intersection.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import RealmSwift
import CocoaLumberjackSwift

//--------------------//
// Intersection Types //
//--------------------//

//  Road Switch
//
//  | ↑ |
//  | B |
//  |   |
//  | ↑ |
//  | * |
//  |   |
//  | A |
//  | ↓ |

//  Turn Right
//   _____________
//  |          B →
//  | ↑  _________
//  | * |
//  |   |
//  | A |
//  | ↓ |

//  Turn Left
//  _____________
//  ← B          |
//  _________  ↑ |
//           | * |
//           |   |
//           | A |
//           | ↓ |

//  Side Road Right
//
//  | ↑ |
//  | A |
//  |   |_________
//  |          B →
//  | ↑  _________
//  | * |
//  |   |
//  | A |
//  | ↓ |
//
// Example: (51.457252, -0.970259) Side Road intersection with roads:
// Blagrave Street and Valpy Street.

//  Side Road Left
//
//           | ↑ |
//           | A |
//  _________|   |
//  ← B          |
//  _________  ↑ |
//           | * |
//           |   |
//           | A |
//           | ↓ |

//  T1
//  ___________________
//  ← B             B →
//  _______     _______
//         | ↑ |
//         | * |
//         |   |
//         | A |
//         | ↓ |
//
// Example: (51.455014, -0.982331) T intersection with roads:
// Russell Street and Oxford Street.
//
// Example: (51.455674, -0.973149) [Issue] T intersection with only (right) road.
// Broad Street and Chain Street.

//  T2
//  ___________________
//  ← B             C →
//  _______     _______
//         | ↑ |
//         | * |
//         |   |
//         | A |
//         | ↓ |

//  Cross1
//         | ↑ |
//         | A |
//  _______|   |_______
//  ← B             B →
//  _______     _______
//         | ↑ |
//         | * |
//         |   |
//         | A |
//         | ↓ |

//  Cross2
//         | ↑ |
//         | A |
//  _______|   |_______
//  ← B             C →
//  _______     _______
//         | ↑ |
//         | * |
//         |   |
//         | A |
//         | ↓ |

//  Multi
//         | ↑ |
//         | D |
//  _______|   |_______
//  ← B             C →
//  _______     _______
//         | ↑ |
//         | * |
//         |   |
//         | A |
//         | ↓ |
//
// Example: (51.455464, -0.975333) Multi (cross) intersection with roads:
// Oxford Road, West Street, Broad Street and St Mary's Butts.

class Intersection: Object, Locatable, Localizable {
    
    // MARK: Types
    
    enum Style: CustomStringConvertible {
        case standard
        case roundabout
        case roadEnd
        case circleDrive
        
        var description: String {
            switch self {
            case .standard:
                return "standard"
            case .roundabout:
                return "roundabout"
            case .roadEnd:
                return "road end"
            case .circleDrive:
                return "circle drive"
            }
        }
    }
    
    // MARK: Realm properties
    
    /// Synthesized primary key for this intersection
    @objc dynamic var key: String = ""
    
    /// Array of the road POIs that meet at this intersection
    let roadIds = List<IntersectionRoadId>()
    
    /// Latitude of the intersection
    @objc dynamic var latitude: CLLocationDegrees = 0.0
    
    /// Longitude of the intersection
    @objc dynamic var longitude: CLLocationDegrees = 0.0
    
    // MARK: Non-Realm Properties
    
    /// The set of roads that participate in this intersection
    var roads: [Road] {
        roadIds.compactMap { SpatialDataCache.road(withKey: $0.id) }
    }
    
    // Some intersections can contain the same road more than once, for example if one road loops back to the intersection.
    // Example: https://www.openstreetmap.org/way/189315310
    var distinctRoads: [Road] {
        return roadIds
            .map { $0.id }
            .dropDuplicates()
            .compactMap { SpatialDataCache.road(withKey: $0) }
    }
    
    var localizedRoadNames: [String] {
        return self.roads
            .map { $0.localizedName }
            .filter { !$0.isEmpty }
            .dropDuplicates()
    }
    
    /// Name of the intersection
    private var _localizedName = ""
    var localizedName: String {
        if _localizedName.isEmpty {
            _localizedName = localizedName()
        }
        
        return _localizedName
    }
    
    /// Calculated property which synthesizes a `CLLocation` object for the location of the intersection
    var location: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
    
    /// Calculated property which synthesizes a `CLLocationCoordinate2D` object for the coordinate of the intersection
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
    
    // MARK: Contructors
    
    /// Constructs an intersection given a GeoJsonFeature representing the intersection
    ///
    /// - Parameter feature: A GeoJsonFeature representing an intersection
    convenience init(feature: GeoJsonFeature) {
        self.init()
        
        for roadId in feature.osmIds {
            self.roadIds.append(IntersectionRoadId(withId: roadId))
            
            self.key += String(roadId)
        }
        
        if let lat = feature.geometry?.point?[1] {
            latitude = lat
        }
        
        if let lon = feature.geometry?.point?[0] {
            longitude = lon
        }
        
        self.key += String(latitude) + String(longitude)
    }
    
    // MARK: Methods
    
    /// Returns the names of properties which Realm should ignore
    ///
    /// - Returns: List of ignored properties
    static override func ignoredProperties() -> [String] {
        return ["roads",
                "distinctRoads",
                "localizedRoadNames",
                "_localizedName",
                "localizedName",
                "location",
                "coordinate"]
    }
    
    /// Indicates which property represents the primary key of this object
    ///
    /// - Returns: The name of the property that represents the primary key of this object
    override static func primaryKey() -> String {
        return "key"
    }
    
    /// Returns the localized name for the intersection, which contains the
    /// localized names of the intersecting roads.
    ///
    /// - Note: `excludedRoadName` will not be respected if it is the only road in the intersection name.
    ///         For example, if the intersection name and `excludedRoadName` is "Pike Street", the name
    ///         will not be excluded.
    ///
    /// - Parameter excludedRoadName: A road name to exclude from the intersection name.
    /// - Returns: The localized name for the intersection.
    func localizedName(excluding excludedRoadName: String? = nil) -> String {
        var localizedRoadNames = self.localizedRoadNames
        
        // Exclude road name if needed
        if let excludedRoadName = excludedRoadName {
            let excluded = localizedRoadNames.filter { $0 != excludedRoadName }
            
            if !excluded.isEmpty {
                localizedRoadNames = excluded
            }
        }
        
        guard !localizedRoadNames.isEmpty else {
            return GDLocalizedString("osm.tag.intersection")
        }
        
        let listFormatter = ListFormatter()
        listFormatter.locale = LocalizationContext.currentAppLocale
        
        return listFormatter.string(from: localizedRoadNames) ?? GDLocalizedString("osm.tag.intersection")
    }
    
    func includesRoad(withLocalizedName localizedName: String) -> Bool {
        return self.roads.contains { $0.localizedName == localizedName }
    }
    
    func isMainIntersection(context: SecondaryRoadsContext = .standard) -> Bool {
        return containAtLeastTwoDistinctMainRoads(context: context)
            || isMainIntersectionWithAClose(context: context)
            || isMainIntersectionOnRoundabout(context: context)
            || containRoadChangeToDifferentType()
            || isTIntersectionWithSameRoad()
    }
    
    func containAtLeastTwoDistinctMainRoads(context: SecondaryRoadsContext = .standard) -> Bool {
        return self.roads
            .filter { $0.isMainRoad(context: context) } // Main roads
            .map { $0.localizedName } // Main road names
            .dropDuplicates() // Distinct main road names
            .count >= 2
    }
    
    /// Determines if this intersection is a main intersection with a close (a single circular road segment).
    /// In order to be a main intersection with a close, the intersection must be between two distinct road segments
    /// (though the road segments may have the same name) and one of the road segments must be a circular path
    /// (starting and ending at the same location).
    ///
    /// - Parameter context: Context that determines which roads should be considered main roads
    /// - Returns: True if this intersection is a main intersection with a close
    func isMainIntersectionWithAClose(context: SecondaryRoadsContext = .standard) -> Bool {
        let main = roads.filter { $0.isMainRoad(context: context) } // Main roads
        
        // There must be at least 2 unique road segments (they can have the same name)
        guard Set(main.map { $0.key }).count > 1 else {
            return false
        }
        
        // One of the road segments must be circular (a.k.a. a "close")
        return main.contains(where: { GeometryUtils.pathIsCircular($0.coordinates ?? []) })
    }
    
    /// Determines if this intersection is a main intersection with a roundabout. Roundabouts can sometimes be
    /// constructed in OSM as a series of unnamed service roads connected in a circle with main roads connecting
    /// to the service roads. Normally, these would not be treated as main intersections if the `context` was set
    /// to `SecondaryRoadContext.strict`, but given the nature of the roundabout itself being a large meta-intersection,
    /// this method promotes those intersections to being considered main intersection (so long as the road connecting
    /// to the roundabout is a main road.
    ///
    /// - Parameter context: Context that determines which roads should be considered main roads
    /// - Returns: True if the intersection is between a main road and a roundabout
    func isMainIntersectionOnRoundabout(context: SecondaryRoadsContext = .standard) -> Bool {
        guard isPartOfRoundabout else {
            return false
        }
        
        return roads.contains { $0.isMainRoad(context: context) }
    }
    
    /// Returns `true` if the intersection intersects two roads with the same `name` but with a different `type`,
    /// such as "primary" and "secondary".
    ///
    /// - Note: The roads should have a valid name.
    ///
    /// - Example: "Bell Street" (service road) intersects with "Bell Street" (primary road).
    /// [OSM node](https://www.openstreetmap.org/node/420339377).
    func containRoadChangeToDifferentType() -> Bool {
        /// Filter all roads that are named
        let roads = self.roads.filter { !$0.name.isEmpty }
        
        /// Filter all roads that "switch" to a different road type
        return roads.contains { (road) -> Bool in
            return roads.contains(where: { $0.key != road.key && $0.name == road.name && $0.type != road.type })
        }
    }
    
    /// Returns `true` if it is a T type intersection for two roads with the same `name`.
    ///
    /// - Example: "The Chase" intersects with "The Chase".
    /// [OSM node](https://www.openstreetmap.org/node/60371908).
    func isTIntersectionWithSameRoad() -> Bool {
        let roads = self.roads
        let intersectionCoordinate = self.coordinate
        
        return roads.contains { (road) -> Bool in
            // Check roads that intersect with their vertices (first or last coordinates).
            // This represents the vertical section of the T.
            guard let roadCoordinates = road.coordinates else { return false }
            guard intersectionCoordinate == roadCoordinates.first || intersectionCoordinate == roadCoordinates.last else { return false }
            
            // Find a similar road that intersect with it's edge (not the first or last coordinates).
            // This represents the horizontal section of the T.
            return roads.contains { (otherRoad) -> Bool in
                guard otherRoad.key != road.key && otherRoad.name == road.name else { return false }
                guard let otherRoadCoordinates = otherRoad.coordinates else { return false }
                
                return intersectionCoordinate != otherRoadCoordinates.first && intersectionCoordinate != otherRoadCoordinates.last
            }
        }
    }
    
}

// MARK: - Helper Methods

extension Intersection {
    
    /// Used to detect if a user is traveling towards a specific location
    private static let defaultDirectionalFieldOfViewAngle: CLLocationDirection = 60.0
    
    /// Returns a filtered array of a given intersections array by specific parameters.
    ///
    /// - Parameters:
    ///    - intersections: The intersections to filter.
    ///    - location: The reference location.
    ///    - direction: The reference direction.
    ///    - directionalFieldOfViewAngle: The reference threshold angle.
    ///    - maxDistance: An upper limit for the distance value to filter.
    ///    - roadName: Filter only intersection containing the given road name.
    ///    - automotive: For an automotive or non-automotive state.
    /// - Returns: A filtered array of `Intersection` objects, sorted by distance, starting from the closest intersection.
    ///
    /// Illustration:
    /// ```
    /// // \    x    /  - (x) intersections
    /// //  \     x /
    /// //   \ x   /    - (\/) directional field of view angle
    /// //    \   /
    /// //      ↑       - (↑) direction
    /// //      o       - (o) location
    /// ```
    static func filter(intersections: [Intersection],
                       for location: CLLocation,
                       direction: CLLocationDirection?,
                       directionalFieldOfViewAngle: CLLocationDirection = Intersection.defaultDirectionalFieldOfViewAngle,
                       maxDistance: CLLocationDistance?,
                       includingRoadName roadName: String? = nil,
                       secondaryRoadsContext: SecondaryRoadsContext = .standard) -> [Intersection] {
        guard intersections.count > 0 else {
            return []
        }
        
        if let direction = direction, !direction.isValid {
            GDLogIntersectionError("Could not respect filter direction (direction is invalid)")
            return []
        }
        
        return intersections
            .map({ (intersection: $0, distance: $0.location.distance(from: location)) })
            .filter { (item) -> Bool in
                // Filter out by distance
                if let maxDistance = maxDistance, maxDistance > 0 {
                    guard item.distance <= maxDistance else {
                        // Intersection is too far
                        return false
                    }
                }
                
                // Filter out by direction
                if let direction = direction {
                    // Check that the direction is towards the intersection
                    let bearingToIntersection = location.coordinate.bearing(to: item.intersection.coordinate)
                    
                    guard let directionRange = DirectionRange(direction: bearingToIntersection, windowRange: directionalFieldOfViewAngle) else {
                        return false
                    }
                    
                    guard directionRange.contains(direction) else {
                        // Direction is not facing the intersection
                        return false
                    }
                }
                
                // Filter out by road name
                if let roadName = roadName {
                    guard item.intersection.includesRoad(withLocalizedName: roadName) else {
                        // Intersection does not contain the road name
                        return false
                    }
                }
                
                // Filter out by main intersections
                guard item.intersection.isMainIntersection(context: secondaryRoadsContext) else {
                    // Intersection is not a main intersection
                    return false
                }
                
                return true
            }
            // Sort results by distance (start of the array contains the closest intersections)
            .sorted(by: { $0.distance < $1.distance })
            .map({ $0.intersection })
    }
    
    static func findClosest(intersections: [Intersection], location: CLLocation) -> Intersection? {
        var closest: Intersection?
        var minDistance: CLLocationDistance = CLLocationDistance.greatestFiniteMagnitude
        
        for intersection in intersections {
            let currentDistance = intersection.location.distance(from: location)
            if currentDistance < minDistance {
                closest = intersection
                minDistance = currentDistance
            }
        }
        
        return closest
    }
    
    /**
     This function resolves the following issue:
     In some cases, there could be multiple intersection objects representing the same intersection at a
     specific coordinate, but with different road objects.
     
     For example, the intersection at [40.755373, -73.987447](https://www.openstreetmap.org/node/42439972)
     which intersects 4 roads is represented by 3 objects, with the following road IDs:
     (167922070, 5673323)
     (167922070, 5673323, 195743209, 195743344)
     (167922070, 195743209)
     
     This function finds the intersection objects that represent the same coordinate and returns
     the one with the most roads.
     */
    static func similarIntersectionWithMaxRoads(intersection: Intersection, intersections: [Intersection]) -> Intersection {
        guard intersections.count > 1 else {
            return intersection
        }
        
        let similarIntersections = intersections.filter { $0.coordinate == intersection.coordinate }
        guard similarIntersections.count > 1 else {
            return intersection
        }
        
        GDLogIntersectionWarn("Intersection is represented with multiple objects (\(similarIntersections.count))")
        similarIntersections.forEach { (intersection) in
            GDLogIntersectionWarn("Intersection ID \(intersection.key)")
        }
        
        guard let intersectionWithMostRoads = similarIntersections.max(by: { $0.roadIds.count < $1.roadIds.count }) else { return intersection }
        
        if intersection.key != intersectionWithMostRoads.key {
            // Log that we prevented an intersection with missing roads to be represented
            GDATelemetry.track("intersection.warning.multiple_objects", with: ["count": String(similarIntersections.count)])
        }
        
        return intersectionWithMostRoads
    }
    
}

// MARK: - Road Direction Calculations

extension Intersection {
    
    /**
     Calculate the directions of all roads in the intersection, relative to a reference heading.
     The returned array is sorted by `Direction` enum order (behind, left, ahead, right, unknown)
     See `roadDirection()` for specific direction calculation info.
     */
    func directions(relativeTo heading: CLLocationDirection) -> [RoadDirection]? {
        let roads = self.roads
        guard roads.count > 0 else { return nil }
        
        var directions: [RoadDirection] = []
        
        // Calculate the directions for each road (each one can have more than one direction)
        for road in roads {
            guard let roadDirections = self.directions(for: road, relativeTo: heading), roadDirections.count > 0 else {
                DDLogWarn("A road direction could not be computed for road with ID: \(road.key)")
                continue
            }
            
            for direction in roadDirections {
                // Check that we don't add the same road and direction twice.
                // For example, in some instances we can have (`Road A`, `left`) twice.
                guard directions.firstIndex(where: { $0.direction == direction.direction && $0.road.name == direction.road.name }) == nil else {
                    DDLogWarn("A road direction has been detected twice, excluding: (\(direction.road.name), \(direction.direction)).")
                    continue
                }
                
                directions.append(direction)
            }
        }
        
        return directions.sorted()
    }
    
    /**
     Calculate the direction of a road in an intersection, relative to a reference heading.
     For example, if the reference heading is 90°, and the road's bearing is 180°, the road's direction will be `right`.
     */
    func directions(for road: Road, relativeTo heading: CLLocationDirection) -> [RoadDirection]? {
        guard let roadCoordinates = road.coordinates, roadCoordinates.count > 1 else {
            DDLogDebug("Road coordinates not valid for road: \(road.name)")
            return nil
        }
        
        // The data in OSM is represented in a way that a road can "touch" an intersection in one of three ways:
        // (touch meaning where a road coordinate equals an intersection coordinate)
        //
        // 1. Road start (leading)
        // ---------
        // * →
        // ---------
        //
        // 2. Road end (trailing)
        // ---------
        //       ← *
        // ---------
        //
        // 3. Along the road (leading & trailing)
        // ---------
        //   ← * →
        // ---------
        
        // Get the intersection coordinate
        let intersectionCoordinate = self.coordinate
        
        // 1. Road start
        if intersectionCoordinate == roadCoordinates.first! {
            guard let bearing = road.bearing() else { return nil }
            let direction = Direction(from: heading, to: bearing, type: .leftRight)
            
            return [RoadDirection(road, bearing, direction)]
        }
        // 2. Road end
        else if intersectionCoordinate == roadCoordinates.last! {
            guard let bearing = road.bearing(reversedDirection: true) else { return nil }
            let direction = Direction(from: heading, to: bearing, type: .leftRight)
            
            return [RoadDirection(road, bearing, direction)]
        }
        // 3. Along the road
        else {
            // Find the intersection coordinate along the road
            guard let intersectionCoordinateIndex = roadCoordinates.firstIndex(of: intersectionCoordinate) else {
                // We did not find a match for the intersection coordinate
                // The road does not contain the intersection coordinate
                DDLogDebug("Could not find an intersection coordinate for road: \(road.name)")
                return nil
            }
            
            // We found the intersection coordinate
            // We now split the road in two in order to calculate each direction from the intersection coordinate
            
            // Create the paths for the leading and trailing directions
            let path1 = Array(roadCoordinates[intersectionCoordinateIndex...])
            let path2 = Array(roadCoordinates[...intersectionCoordinateIndex].reversed())
            
            var directions: [RoadDirection] = []
            
            // Calculate the bearing and direction of the first path
            if let path1Bearing = GeometryUtils.pathBearing(for: path1, maxDistance: GeometryUtils.maxRoadDistanceForBearingCalculation) {
                let direction = Direction(from: heading, to: path1Bearing, type: .leftRight)
                directions.append(RoadDirection(road, path1Bearing, direction))
            }
            
            // Calculate the bearing and direction of the second path
            if let path2Bearing = GeometryUtils.pathBearing(for: path2, maxDistance: GeometryUtils.maxRoadDistanceForBearingCalculation) {
                let direction = Direction(from: heading, to: path2Bearing, type: .leftRight)
                directions.append(RoadDirection(road, path2Bearing, direction))
            }
            
            return directions
        }
    }
    
}

// MARK: - Roundabout Calculations

extension Intersection {
    
    /// Indicating if the intersection is a part of a roundabout.
    /// Returns `true` if at least one of the roads is part of a roundabout.
    var isPartOfRoundabout: Bool {
        return !roundaboutRoads.isEmpty
    }
    
    /// Returns the roundabout object the intersection is a part of.
    /// - note: Only valid for intersections which are part of roundabouts.
    var roundabout: Roundabout? {
        return Roundabout(intersection: self)
    }
    
    /// Returns the roads that connect to the intersection and are a part of a roundabout.
    var roundaboutRoads: [Road] {
        return self.roads.filter { $0.roundabout }
    }
    
}
