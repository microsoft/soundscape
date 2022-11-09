//
//  Roundabout.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit
import CocoaLumberjackSwift

/// Roundabouts are synthesized objects we calculate from specific intersections
struct Roundabout {
    
    // MARK: Constants
    
    /// Used to determine if a roundabout is large.
    private static let minDistanceForLargeRoundabout = CLLocationDistance(90)
    
    // MARK: Properties
    
    let localizedName: String?
    let intersection: Intersection
    private let exits: [Intersection: [Road]]

    /// A roundabout is considered large when the maximum distance from the original intersection
    /// to any other intersection (exit) is more than 90 meters.
    var isLarge: Bool {
        return Roundabout.maxDistance(from: intersection, to: Array(exits.keys)) > Roundabout.minDistanceForLargeRoundabout
    }

    // MARK: Initialization
    
    /// Initializing a roundabout from an Intersection.
    /// - Note: `nil` will be returned in cases where the intersection is not part of a roundabout,
    /// or the roundabout exits could not be calculated.
    init?(intersection: Intersection) {
        guard intersection.isPartOfRoundabout else {
            return nil
        }
        
        guard let exits = Roundabout.exits(for: intersection) else {
            return nil
        }
        
        self.intersection = intersection
        self.exits = exits
        self.localizedName = Roundabout.roundaboutLocalizedName(for: intersection)
    }
    
    // MARK: Methods

    func contains(_ intersection: Intersection) -> Bool {
        return exits.keys.contains(intersection)
    }
    
}

// MARK: - Name

extension Roundabout {
    /// We derive the roundabout name from a road that is a part of it.
    /// In some cases, roads don't have specific names, so we synthesize them from their OSM tags.
    /// These are the synthesized names we don't want to use for roundabouts.
    private static var invalidRoundaboutNames: [String] {
        return [GDLocalizedString("osm.tag.road"),
                GDLocalizedString("osm.tag.highway"),
                GDLocalizedString("osm.tag.roundabout"),
                GDLocalizedString("osm.tag.residential_street"),
                GDLocalizedString("osm.tag.walking_path"),
                GDLocalizedString("osm.tag.bicycle_path"),
                GDLocalizedString("osm.tag.service_road")]
    }
    
    static func roundaboutLocalizedName(for intersection: Intersection) -> String? {
        guard let localizedName = intersection.roundaboutRoads.first?.localizedName else { return nil }
        
        let lowercasedName = localizedName.lowercasedWithAppLocale()
        let lowercasedInvalidNames = Roundabout.invalidRoundaboutNames.map { $0.lowercasedWithAppLocale() }
        
        guard !lowercasedInvalidNames.contains(lowercasedName) else {
            return nil
        }
        
        return localizedName
    }
}

// MARK: - Road Directions

extension Roundabout {
    func exitDirections(relativeTo heading: CLLocationDirection) -> [RoadDirection]? {
        var roundaboutExitDirections = [RoadDirection]()
        
        for (intersection, roads) in exits {
            for road in roads {
                guard let directions = intersection.directions(for: road, relativeTo: heading) else {
                    continue
                }
                
                for direction in directions {
                    // Check that we don't add the same exit and direction twice.
                    // For example, in some instances we can have (`Road A`, `left`) twice.
                    guard roundaboutExitDirections.firstIndex(where: { $0.direction == direction.direction && $0.road.name == direction.road.name }) == nil else {
                        DDLogWarn("An exit direction has been detected twice, excluding: <\(direction.road.name), \(direction.direction)>.")
                        continue
                    }
                    
                    roundaboutExitDirections.append(direction)
                }
            }
        }
        
        return roundaboutExitDirections.sorted()
    }
}

// MARK: - Intersection Roundabout Calculations

extension Roundabout {
    
    /// Returns a key-value map with the all the intersections that are part of the same roundabout,
    /// and the exit roads for each intersection.
    /// This represent the roundabout object that connects to the intersection.
    fileprivate static func exits(for intersection: Intersection) -> [Intersection: [Road]]? {
        guard intersection.isPartOfRoundabout else { return nil }
        
        var visited = Set<Intersection>()
        return Roundabout.exits(intersection: intersection, visited: &visited)
    }
    
    /**
     Returns a key-value map with the all the intersections that are part of the same roundabout,
     and the exit roads for each intersection.
     This represent the roundabout object that connects to the intersection.
     
     In OSM, some roundabouts are represented as one `way` object, others by a number of connected `way` objects.
     These roundabouts are 'connected' to other roads ('exits') by sharing `node` objects (our `Intersection` object).
     There is no straightforward way to get all the intersections and roads that connect to a roundabout, and this
     method tries to solve that.
     
     The algorithm iterates recursively over the roads connected to a given intersection and tries to map a roundabout
     by it's connected parts (intersections and roads).
     
     The algorithm works as folows:
     1. Iterate over the roads of a given intersection
     2.   For roads that ARE NOT marked as part of a roundabout
     3.   - Mark them as 'exits'
     4.   For roads that ARE marked as part of a roundabout
     5.   - Get the list of intersections that lie on that road (except the given intersection)
     6.   - For every intersection, go recursively to step 1
     7. Return all the intersections and roads that represent the roundabout exits
     */
    private static func exits(intersection: Intersection, visited: inout Set<Intersection>) -> [Intersection: [Road]] {
        visited.insert(intersection)
        
        var allExits = [Intersection: [Road]]()
        var currentExits = [Road]()
        
        let lowercasedSecondaryRoadNames = SecondaryRoadsContext.standard.localizedSecondaryRoadNames.map({ $0.lowercasedWithAppLocale() })
        
        for road in intersection.roads {
            // Ignore secondary roads
            guard !lowercasedSecondaryRoadNames.contains(road.localizedName.lowercasedWithAppLocale()) else {
                continue
            }
            
            // Mark non-roundabout roads as exits
            guard road.roundabout else {
                currentExits.append(road)
                continue
            }
            
            // Get the list of intersections that lie on that road (except the given intersection)
            let region = MKCoordinateRegion(center: intersection.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            guard let roadIntersections = SpatialDataCache.intersections(forRoadKey: road.key, inRegion: region),
                !roadIntersections.isEmpty else {
                    continue
            }
            
            for roadIntersection in roadIntersections {
                // Ignore the current intersection
                guard !roadIntersection.isEqual(intersection) else {
                    continue
                }
                
                // Ignore visited intersections
                guard !visited.contains(roadIntersection) else {
                    continue
                }
                
                // Recursively get the roundabout exits for the current intersection
                let result = Roundabout.exits(intersection: roadIntersection, visited: &visited)
                guard !result.isEmpty else {
                    continue
                }
                
                // Merge the results
                allExits.merge(result, uniquingKeysWith: { (roads1, roads2) -> [Road] in
                    return roads1 + roads2
                })
            }
        }
        
        // Add the current intersection's exits to the results
        if !currentExits.isEmpty {
            allExits[intersection] = currentExits
        }
        
        return allExits
    }
    
}

// MARK: - Helper

extension Roundabout {
    /// Returns the distance from an origin intersection to the farthest intersection in the given array.
    fileprivate static func maxDistance(from intersection: Intersection, to intersections: [Intersection]) -> CLLocationDistance {
        guard !intersections.isEmpty else {
            return 0.0
        }
        
        let intersectionLocation = intersection.location
        var maxDistance = CLLocationDistance(0.0)
        
        for int in intersections {
            let distance = int.location.distance(from: intersectionLocation)
            if distance > maxDistance {
                maxDistance = distance
            }
        }
        
        return maxDistance
    }
}
