//
//  SpatialDataView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

class SpatialDataView: SpatialDataViewProtocol {
    
    // MARK: Private Properties
    
    private weak var geolocationManager: GeolocationManagerProtocol?
    private weak var motionActivityContext: MotionActivityProtocol?

    /// Tile data encompassed by the current spatial data view
    private let tiles: [TileData]
    
    /// The current destination
    private let destination: ReferenceEntity?
    
    // The current set of user defined PORs
    private let genericLocations: [POI]
    
    /// A set of OSM IDs used to prevent duplicate entities when merging entities across tiles
    private var ids: Set<String> = []
    
    // MARK: Public Properties
    
    let markedPoints: [ReferenceEntity]
    
    /// Aggregated list of all POIs in the current spatial data view
    lazy var pois: [POI] = {
        var pois: [POI] = []
        
        for marker in markedPoints {
            let poi = marker.getPOI()
            
            // Add POI
            ids.insert(poi.key)
            pois.append(poi)
            
            if let matchable = poi as? MatchablePOI {
                for key in matchable.matchKeys {
                    // Add all keys for matching POIs
                    // to avoid duplicate POIs
                    ids.insert(key)
                }
            }
        }
        
        // Make sure any destinations not in the current tiles still get added to the list of POIs
        if let destinationEntity = destination?.getPOI(), !ids.contains(destinationEntity.key) {
            ids.insert(destinationEntity.key)
            pois.append(destinationEntity)
            
            if let matchable = destinationEntity as? MatchablePOI {
                for key in matchable.matchKeys {
                    // Add all keys for matching POIs
                    // to avoid duplicate POIs
                    ids.insert(key)
                }
            }
        }
        
        // Gather all of the POIs (excluding entrances since they are special)
        for tile in tiles {
            for poi in tile.pois {
                guard poi.superCategory != SuperCategory.entrances.rawValue, !ids.contains(poi.key) else {
                    continue
                }
                
                ids.insert(poi.key)
                pois.append(poi)
                
                if let matchable = poi as? MatchablePOI {
                    for key in matchable.matchKeys {
                        // Add all keys for matching POIs
                        // to avoid duplicate POIs
                        ids.insert(key)
                    }
                }
            }
        }
        
        // Make sure any pors in the current tiles still get added to the list of POIs
        for poi in genericLocations where !ids.contains(poi.key) {
            ids.insert(poi.key)
            pois.append(poi)
            
            if let matchable = poi as? MatchablePOI {
                for key in matchable.matchKeys {
                    // Add all keys for matching POIs
                    // to avoid duplicate POIs
                    ids.insert(key)
                }
            }
        }
        
        return pois
    }()
    
    /// Aggregated list of all intersections in the current spatial data view.
    lazy var intersections: [Intersection] = {
        var intersections: [Intersection] = []
        
        for tile in tiles {
            for intersection in tile.intersections {
                guard !ids.contains(intersection.key) else {
                    continue
                }
                
                ids.insert(intersection.key)
                intersections.append(intersection)
            }
        }
        
        return intersections
    }()
    
    /// Aggregated list of all roads in the current spatial data view
    lazy var roads: [Road] = {
        var roads: [Road] = []
        
        for tile in tiles {
            for road in tile.roads {
                guard !ids.contains(road.key) else {
                    continue
                }
                
                ids.insert(road.key)
                roads.append(road)
            }
        }
        
        return roads
    }()
    
    // MARK: - Initialization
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - location: User's current location
    ///   - range: The distance to search for POI within
    ///   - zoom: The tile zoom level (generally locked to 16)
    ///   - geolocation: The GeolocationContext object
    ///   - motionActivity: The MotionActivityContext object
    ///   - destinationManager: The DestinationManager object
    init(location: CLLocation, range: CLLocationDistance, zoom: UInt, geolocation: GeolocationManagerProtocol?, motionActivity: MotionActivityProtocol?, destinationManager: DestinationManagerProtocol) {
        let vectorTiles = VectorTile.tilesForRegion(location, radius: range, zoom: zoom)
        
        // Get the tile data for the specified tiles
        tiles = SpatialDataCache.tileData(for: vectorTiles)
        
        // Get the marked points
        markedPoints = SpatialDataCache.referenceEntitiesNear(location.coordinate, range: range)
        
        // Get the generic locations (these will get merged with the regular POIs)
        genericLocations = SpatialDataCache.genericLocationsNear(location, range: range)
        
        // Store references to context objects
        geolocationManager = geolocation
        motionActivityContext = motionActivity
        
        // Retrieve destination
        destination = destinationManager.destination
    }
    
    // MARK: - Class Methods

    /// Calculates the bounds of the quadrants that should be used for filtering POIs for
    /// Orient and Explore. These quadrants are rotated from the standard cardinal direction
    /// quadrants (north: [315.0, 45.0), east: [45.0, 135.0), etc.) such that the provided
    /// heading becomes the center of the standard cardinal direction quadrant that it belongs
    /// to. This ensures that callouts filtered into quadrants will always be centered around
    /// the user's current heading if possible (if quadrants were fixed to the standard cardinal
    /// direction, and the user were facing 315.0, then all callouts for `.north` would be to the
    /// user's right).
    ///
    /// Here are several examples to illustrate how this works:
    ///
    /// * **Heading := 0.0**: In this case, the heading is already aligned with the center of
    ///                       the `.north` quadrant, so the standard cardinal direction quadrants
    ///                       are returned. Quadrants returned:
    ///
    ///    north: [315.0, 45.0)
    ///
    ///    east: [45.0, 135.0)
    ///
    ///    south: [135.0, 225.0)
    ///
    ///    west: [225.0, 315.0)
    ///
    ///
    /// * **Heading := 95.0**: In this case, the heading is in the `.east` quadrant, but it is rotated
    ///                       5.0 degrees clockwise from the center of the `.east` quadrant, so the
    ///                       standard cardinal direction quadrants are rotated 5.0 degrees clockwise.
    ///                       Quadrants returned:
    ///
    ///    north: [320.0, 50.0)
    ///
    ///    east: [50.0, 140.0)
    ///
    ///    south: [140.0, 230.0)
    ///
    ///    west: [230.0, 320.0)
    ///
    ///
    /// * **Heading := 230.0**: In this case, the heading is in the `.west` quadrant, but it is rotated
    ///                       40.0 degrees counter-clockwise from the center of the `.west` quadrant, so
    ///                       the standard cardinal direction quadrants are rotated 40.0 degrees
    ///                       counter-clockwise. Quadrants returned:
    ///
    ///    north: [275.0, 5.0)
    ///
    ///    east: [5.0, 95.0)
    ///
    ///    south: [95.0, 185.0)
    ///
    ///    west: [185.0, 275.0)
    ///
    ///
    /// - Parameter heading: The device's current heading or course
    /// - Returns: Quadrants realigned to the provided heading. Always four quadrants in the order [.north, .east, .south, .west]
    class func getQuadrants(heading: CLLocationDirection) -> [Quadrant] {
        // Find the quadrant the heading is currently in
        let quadrantIndex = Int((heading + 45.0).truncatingRemainder(dividingBy: 360.0)) / 90
        
        // If the current heading isn't in the north quadrant, add 90 degrees to the heading until it is in the north quadrant
        let northHeading = quadrantIndex == 0 ? heading : (heading + 90 * Double(4 - quadrantIndex)).truncatingRemainder(dividingBy: 360.0)
        
        // Define the quadrants based off of this offset heading to the north
        return [
            Quadrant(heading: northHeading),         // North
            Quadrant(heading: northHeading + 90.0),  // East
            Quadrant(heading: northHeading + 180.0), // South
            Quadrant(heading: northHeading + 270.0)  // West
        ]
    }
    
    /// Returns the cardinal direction (see `CompassDirection`) that the provided heading is
    /// currently in.
    ///
    /// - Parameter heading: The user's heading vector
    /// - Returns: The `CompassDirection` the provided vector falls in
    class func getHeadingDirection(heading: CLLocationDirection) -> CompassDirection {
        let quadrants = SpatialDataView.getQuadrants(heading: heading)
        
        return CompassDirection.from(bearing: heading, quadrants: quadrants)
    }

    /// Returns a POI filter used by a user activity.
    /// - Note: If the user activity does not requires a specific filter, `nil` will be returned.
    ///
    /// - Parameter motionActivity: A motion activity that encapsulates the user activity
    /// - Returns: The specific filter for the user activity, or `nil`
    class func filter(for motionActivity: MotionActivityProtocol) -> FilterPredicate? {
        if motionActivity.isInVehicle {
            // In a vehicle we only care about landmarks and bus stops
            return CompoundPredicate(orPredicateWithSubpredicates: [Filter.superCategory(expected: SuperCategory.landmarks),
                                                                    Filter.type(expected: SecondaryType.transitStop)])
        }
        return nil
    }
}
