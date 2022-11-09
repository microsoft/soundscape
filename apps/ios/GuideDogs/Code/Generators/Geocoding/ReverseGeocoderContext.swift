//
//  ReverseGeocoderContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol ReverseGeocoder: AnyObject {
    func reverseGeocode(_ location: CLLocation) -> ReverseGeocoderResult?
    func reverseGeocode(_ location: CLLocation, data: SpatialDataViewProtocol, heading: Heading) -> ReverseGeocoderResult
}

class ReverseGeocoderContext: ReverseGeocoder {
    // MARK: Static Properties
    
    private static let alongRoadThreshold: CLLocationDistance = 20.0 // meters
    private static let nearIntersectionDistance: CLLocationDistance = 30.0 // meters
    private static let intersectionDistanceThreshold: CLLocationDistance = 500.0 // meters
    private static let travelDirectionAngleThreshold: CLLocationDirection = 90.0 // degrees (0 - 360)

    // MARK: - Properties
    
    private weak var spatialDataContext: SpatialDataProtocol?
    private var lastAnnouncedResult: ReverseGeocoderResult?
    private var previousRoadKey: String?
    
    // MARK: Computed Properties
    
    private var isInVehicle: Bool {
        return spatialDataContext?.motionActivityContext.isInVehicle ?? false
    }
    
    // MARK: - Public API
    
    init(spatialDataContext dataContext: SpatialDataProtocol) {
        // Store references to other contexts that we will need to observe notifications from
        spatialDataContext = dataContext
    }
    
    /// Reverse geocodes a location into 1 of 4 possible states (within a POI, alongside a
    /// road, general location, unknown location) using the default `SpatialDataView` for
    /// the provided location (e.g. the roads and POIs in the tiles curently surrounding the
    /// user) and the default collection heading.
    ///
    /// - Parameters:
    ///   - location: The user's current location
    func reverseGeocode(_ location: CLLocation) -> ReverseGeocoderResult? {
        guard let dataView = spatialDataContext?.getDataView(for: location, searchDistance: SpatialDataContext.initialPOISearchDistance) else {
            GDLogGeocoderInfo("Unable to get POIs, can't reverse geocode")
            return nil
        }
        
        let heading = AppContext.shared.geolocationManager.collectionHeading
        return reverseGeocode(location, data: dataView, heading: heading)
    }
    
    /// Reverse geocodes a location into 1 of 4 possible states (within a POI, alongside a
    /// road, general location, unknown location) using the provided `SpatialDataView` (e.g. the roads
    /// and POIs in the tiles surrounding the provided location)
    ///
    /// - Parameters:
    ///   - location: The location to reverse geocode
    ///   - dataView: The current `SpatialDataView`
    ///   - heading: The heading to use when generating geocoder results
    func reverseGeocode(_ location: CLLocation, data: SpatialDataViewProtocol, heading: Heading) -> ReverseGeocoderResult {
        // Assumption: if the user is within a building, that building POI is within the nearest 20 POIs
        let sortPredicate = Sort.distance(origin: location)
        let entities = data.pois.sorted(by: sortPredicate, maxLength: 20)
        
        // Check to see if the user is inside a building
        for entity in entities where entity.contains(location: location.coordinate) {
            let isDest = spatialDataContext?.destinationManager.isDestination(key: entity.key) ?? false
            let res = InsideGeocoderResult(location: location, heading: heading, key: entity.key, wasDestination: isDest)
            logState(res)
            
            // We are indoors, so clear the previous road key (the user can't be stuck to a road if they are indoors)
            previousRoadKey = nil
            
            return res
        }
        
        // Save the nearest POI (we aren't sure yet if this is going to be an alongside road location or a generic location)
        var poiKey: String?
        var poiIsDestination: Bool = false
        if let entity = entities.first {
            poiKey = entity.key
            poiIsDestination = spatialDataContext?.destinationManager.isDestination(key: entity.key) ?? false
        }
        
        // We are not inside a building, so check if the user is alongside a road
        let searchResult = ReverseGeocoderContext.findNearestRoads(data.roads, location: location, stickyRoadKey: previousRoadKey)
        
        if searchResult.closest != nil {
            // Default to selecting the closest road
            var selectedRoad: Road! = searchResult.closest
            var selectedRoadLocation: CLLocation! = searchResult.closestLocation
            
            previousRoadKey = selectedRoad.key
            
            // Only store an intersection if the user is alongside the nearest road
            if searchResult.closestDistance < ReverseGeocoderContext.alongRoadThreshold {
                
                let closestIntersection = Intersection.findClosest(intersections: data.intersections, location: location)
                
                // Check if we should still be stuck to the sticky road (only when we are close to an intersection)
                if searchResult.sticky != nil, shouldStickToRoad(distanceFromRoad: searchResult.stickyDistance, location: location, closestIntersection: closestIntersection) {
                    selectedRoad = searchResult.sticky
                    selectedRoadLocation = searchResult.stickyLocation
                    previousRoadKey = searchResult.sticky!.key
                }
                
                // Since the user is near a road, find the closest intersection
                let filteredIntersections = Intersection.filter(intersections: data.intersections,
                                                                for: location,
                                                                direction: heading.value,
                                                                directionalFieldOfViewAngle: ReverseGeocoderContext.travelDirectionAngleThreshold,
                                                                maxDistance: ReverseGeocoderContext.intersectionDistanceThreshold,
                                                                includingRoadName: selectedRoad.localizedName,
                                                                secondaryRoadsContext: AppContext.secondaryRoadsContext)
                
                let intersection: Intersection? = filteredIntersections.first
                
                if intersection == nil {
                    GDLogLocationError("In \"alongside road\" state, but no intersections returned from intersection filter!")
                }
                
                let res = AlongsideGeocoderResult(location: location,
                                                  heading: heading,
                                                  roadKey: selectedRoad.key,
                                                  roadLocation: selectedRoadLocation,
                                                  closestRoadKey: searchResult.closest!.key,
                                                  closestRoadLocation: searchResult.closestLocation!,
                                                  intersectionKey: intersection?.key)
                logState(res)
                return res
            }
            
            // The location isn't alongside a road, so return a generic result
            let res = GenericGeocoderResult(location: location,
                                            heading: heading,
                                            roadKey: selectedRoad.key,
                                            roadLocation: selectedRoadLocation,
                                            closestRoadKey: searchResult.closest!.key,
                                            closestRoadLocation: searchResult.closestLocation!,
                                            poiKey: poiKey,
                                            wasDestination: poiIsDestination)
            logState(res)
            return res
        }
        
        // There are no nearby roads, so clear the previous road key
        previousRoadKey = nil
        
        // The location isn't alongside a road (and we couldn't find a nearby road), so return a generic result
        let res = GenericGeocoderResult(location: location, heading: heading, poiKey: poiKey, wasDestination: poiIsDestination)
        logState(res)
        return res
    }
    
    // MARK: - Private API
    
    /// Logs the current state of the `ReverseGeocoderContext`
    private func logState(_ result: ReverseGeocoderResult) {
        switch result {
        case let inside as InsideGeocoderResult:
            GDLogLocationVerbose("[RG]: state (inside)")
            GDLogLocationVerbose("[RG]:     Coordinate: \(inside.location.description)")
            GDLogLocationVerbose("[RG]:     POI:        \(inside.poi?.localizedName ?? "unknown")")
        case let alongside as AlongsideGeocoderResult:
            GDLogLocationVerbose("[RG]: state (alongside)")
            GDLogLocationVerbose("[RG]:     Coordinate:   \(alongside.location.description)")
            GDLogLocationVerbose("[RG]:     Road:         \(alongside.road?.localizedName ?? "unknown")")
            GDLogLocationVerbose("[RG]:     Intersection: \(alongside.intersection?.localizedName ?? "unknown")")
            GDLogLocationVerbose("[RG]:     Address:      \(alongside.estimatedAddress?.streetName ?? "unknown")")
        case let generic as GenericGeocoderResult:
            GDLogLocationVerbose("[RG]: state (other)")
            GDLogLocationVerbose("[RG]:     Coordinate: \(generic.location.description)")
            GDLogLocationVerbose("[RG]:     Road:       \(generic.road?.localizedName ?? "unknown")")
            GDLogLocationVerbose("[RG]:     POI:        \(generic.poi?.localizedName ?? "unknown")")
        default:
            GDLogLocationVerbose("[RG]: state (unknown)")
        }
    }
    
    private func shouldStickToRoad(distanceFromRoad stickyDistance: CLLocationDistance, location: CLLocation, closestIntersection: Intersection?) -> Bool {
        // Sticky road logic should only apply when near an intersection
        guard let closestIntersection = closestIntersection else {
            return false
        }
        
        // Sticky road logic should only apply when near an intersection
        guard closestIntersection.location.distance(from: location) < ReverseGeocoderContext.nearIntersectionDistance else {
            return false
        }
        
        // The sticky road must be within the `alongRoadThreshold` for sticky logic to apply
        guard stickyDistance < ReverseGeocoderContext.alongRoadThreshold else {
            return false
        }
        
        return true
    }

    // MARK: - Static Helpers
    
    static func closestIntersection(for detail: LocationDetail) -> Intersection? {
        guard let dataView = AppContext.shared.spatialDataContext.getDataView(for: detail.location) else {
            return nil
        }
        
        let namedRoads = dataView.roads.filter({ !$0.name.isEmpty })
        let result = ReverseGeocoderContext.findNearestRoads(namedRoads.isEmpty ? dataView.roads : namedRoads, location: detail.location, stickyRoadKey: nil)
        
        guard let closestRoad = result.closest, let closestLocation = result.closestExistingLocation else {
            return nil
        }
        
        // If the closest existing location isn't actually an intersection, then create a synthesized one and return it
        guard let intersection = SpatialDataCache.intersection(forRoadKey: closestRoad.key, atCoordinate: closestLocation.coordinate) else {
            let synthesized = Intersection()
            
            synthesized.key = UUID().uuidString
            synthesized.latitude = closestLocation.coordinate.latitude
            synthesized.longitude = closestLocation.coordinate.longitude
            synthesized.roadIds.append(IntersectionRoadId(withId: closestRoad.key))
            
            return synthesized
        }
        
        return intersection
    }
    
    private static func findNearestRoads(_ roads: [Road], location usersLocation: CLLocation, stickyRoadKey: String?) -> NearbyRoadSearchResult {
        let zoomLevel: UInt = 23
        let res: Double = VectorTile.groundResolution(latitude: usersLocation.coordinate.latitude, zoom: zoomLevel)
        
        // Maintain two minimum distances. The first is the minimum distance to the currently selected road (e.g.
        // the "sticky" road). The second is the minimum distance to any road. Maintaining the first allows for
        // only switching to a new road when we are sure the user has moved away from their current road. The second
        // allows for selecting the nearest road initially and when the user moves between two roads.
        
        var minStickyDistance = CLLocationDistanceMax
        var closestStickyRoad: Road?
        var closestStickyLat: CLLocationDegrees = 0.0
        var closestStickyLon: CLLocationDegrees = 0.0
        
        var minDistance: CLLocationDistance = CLLocationDistanceMax
        var closestRoad: Road?
        var closestLat: CLLocationDegrees = 0.0
        var closestLon: CLLocationDegrees = 0.0
        var closestExistingLat: CLLocationDegrees = 0.0
        var closestExistingLon: CLLocationDegrees = 0.0
        
        // Look up the sticky road
        var stickyRoad: Road?
        if let key = stickyRoadKey {
            stickyRoad = SpatialDataCache.searchByKey(key: key) as? Road
        }
        
        // Find the nearest road
        for road in roads {
            guard let osmEntity = road as? GDASpatialDataResultEntity else {
                continue
            }
            
            guard let points = osmEntity.coordinates as? GALine else { continue }

            let isStickyRoad = stickyRoad?.localizedName == road.localizedName
            var previous: CLLocationCoordinate2D?

            for point in points {
                guard previous != nil else {
                    previous = point.toCoordinate()
                    continue
                }
                
                let current = point.toCoordinate()
                
                // Calculate the distance from the user's location to the road segment
                let (dist, lat, lon) = GeometryUtils.squaredDistance(location: usersLocation.coordinate,
                                                                     start: previous!,
                                                                     end: current,
                                                                     zoom: zoomLevel)
                
                // Get min along the current road
                if isStickyRoad, dist < minStickyDistance {
                    minStickyDistance = dist
                    closestStickyRoad = road
                    closestStickyLat = lat
                    closestStickyLon = lon
                }
                
                // Get the min along all roads
                if dist < minDistance {
                    minDistance = dist
                    closestRoad = road
                    // Update the synthesized points
                    closestLat = lat
                    closestLon = lon
                    // Update the actual point within the
                    // road data
                    closestExistingLat = current.latitude
                    closestExistingLon = current.longitude
                }
                
                // Store the end of this segment as the beginning of the next
                previous = current
            }
        }
        
        // Build locations to return
        let closestRoadLocation = CLLocation(latitude: closestLat, longitude: closestLon)
        let closestStickyRoadLocation = CLLocation(latitude: closestStickyLat, longitude: closestStickyLon)
        
        var closestExistingLocation: CLLocation?
        
        if closestExistingLat != 0.0, closestExistingLon != 0.0 {
            closestExistingLocation = CLLocation(latitude: closestExistingLat, longitude: closestExistingLon)
        }
        
        return NearbyRoadSearchResult(closestRoad,
                                      closestRoadLocation,
                                      sqrt(minDistance) * res,
                                      closestStickyRoad,
                                      closestStickyRoadLocation,
                                      sqrt(minStickyDistance) * res,
                                      closestExistingLocation)
    }
    
    private struct NearbyRoadSearchResult {
        let closest: Road?
        // This is a synthesized location that exists
        // somewhere along the connected road data
        let closestLocation: CLLocation?
        let closestDistance: CLLocationDistance
        
        // This is an actual location that exists
        // within the road data (e.g. not synthesized)
        let closestExistingLocation: CLLocation?
        
        let sticky: Road?
        let stickyLocation: CLLocation?
        let stickyDistance: CLLocationDistance
        
        init(_ closestRoad: Road?,
             _ closestLoc: CLLocation?,
             _ closestDist: CLLocationDistance,
             _ stickyRoad: Road?,
             _ stickyLoc: CLLocation?,
             _ stickyDist: CLLocationDistance,
             _ closestExistingLoc: CLLocation?) {
            closest = closestRoad
            closestLocation = closestLoc
            closestDistance = closestDist
            sticky = stickyRoad
            stickyLocation = stickyLoc
            stickyDistance = stickyDist
            closestExistingLocation = closestExistingLoc
        }
    }
}
