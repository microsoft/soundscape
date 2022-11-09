//
//  SpatialDataCache.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import RealmSwift
import MapKit

extension SpatialDataCache {
    
    struct Predicates {
        
        static func nickname(_ text: String) -> NSPredicate {
            return NSPredicate(format: "nickname CONTAINS[c] %@", text)
        }
        
        static let lastSelectedDate = NSPredicate(format: "lastSelectedDate != NULL")
        
        static func distance(_ coordinate: CLLocationCoordinate2D,
                             span: CLLocationDistance? = nil,
                             latKey: String = "centroidLatitude",
                             lonKey: String = "centroidLongitude") -> NSPredicate {
            let range = span ?? SpatialDataContext.cacheDistance * 2
            
            return NSPredicate(centerCoordinate: coordinate,
                               span: range, /* `span` is the diameter */
                               latitudeKey: latKey,
                               longitudeKey: lonKey)
        }

        static func isTemporary(_ flag: Bool) -> NSPredicate {
            return NSPredicate(format: "isTemp = %@", NSNumber(value: flag))
        }
    }
}

class SpatialDataCache: NSObject {
    
    // MARK: Geocoders
    
    private static var geocoder: Geocoder?
    
    static func useDefaultGeocoder() {
        self.geocoder = Geocoder(geocoder: CLGeocoder())
    }
    
    static func register(geocoder: AddressGeocoderProtocol) {
        self.geocoder = Geocoder(geocoder: geocoder)
    }
    
    // MARK: Search Providers
    
    private static var poiSearchProviders: [POISearchProviderProtocol] = []
    private static let osmPoiSearchProvider = OSMPOISearchProvider()
    
    static func useDefaultSearchProviders() {
        register(provider: osmPoiSearchProvider)
        register(provider: AddressSearchProvider())
        register(provider: GenericLocationSearchProvider())
    }
    
    static func register(provider: POISearchProviderProtocol) {
        guard !poiSearchProviders.contains(where: { $0.providerName == provider.providerName }) else {
            return
        }
        
        poiSearchProviders.append(provider)
    }
    
    static func removeAllProviders() {
        poiSearchProviders = []
    }
 
    // MARK: Realm Search
    
    fileprivate static func objectsFromAllProviders(predicate: NSPredicate) -> [POI] {
        var pois: [POI] = []
        
        for provider in poiSearchProviders {
            let providerPOIs = provider.objects(predicate: predicate)
            pois.append(contentsOf: providerPOIs)
        }
        
        return pois
    }
    
    static func genericLocationsNear(_ location: CLLocation, range: CLLocationDistance? = nil) -> [POI] {
        guard let index = poiSearchProviders.firstIndex(where: { $0.providerName == "GenericLocationSearchProvider" }) else {
            return []
        }
        
        let predicate = Predicates.distance(location.coordinate,
                                            span: range != nil ? range! * 2 : nil,
                                            latKey: "latitude",
                                            lonKey: "longitude")
        
        return poiSearchProviders[index].objects(predicate: predicate)
    }
    
    /// Search all caches for a POI with the given key. Keys should be unique
    /// across all POI types, so this will return the first POI any POISearchProviderProtocol
    /// object finds
    ///
    /// - Parameter key: The key to search for
    /// - Returns: Optionally a POI instance if one is found
    static func searchByKey(key: String) -> POI? {
        // In release builds, the default search provider (`POISearchProvider()`) is set in
        // `AppDelegate.applicationDidFinishLaunchingWithOptions`. In unit tests, you should
        // set the search provider in the `setUp` method of your unit test class (and call
        // `SpatialDataSearch.removeAllProviders()` in the `tearDown` method).
        assert(!poiSearchProviders.isEmpty, "A search provider must be specified for SpatialDataSearch")
        
        for provider in poiSearchProviders {
            if let poi = provider.search(byKey: key) {
                return poi
            }
        }
        
        return nil
    }
    
    // MARK: Road Entities

    static func road(withKey key: String) -> Road? {
        return osmPoiSearchProvider.search(byKey: key) as? Road
    }
    
    static func roads(withPredicate predicate: NSPredicate) -> [Road]? {
        return osmPoiSearchProvider.objects(predicate: predicate) as? [Road]
    }
    
    // MARK: Routes
    
    static func routeByKey(_ key: String) -> Route? {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return nil
            }
            
            return database.object(ofType: Route.self, forPrimaryKey: key)
        }
    }
    
    static func routes(withPredicate predicate: NSPredicate? = nil) -> [Route] {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return []
            }
            
            let results: Results<Route>
            
            if let predicate = predicate {
                results = database.objects(Route.self).filter(predicate)
            } else {
                results = database.objects(Route.self)
            }
            
            return Array(results)
        }
    }
    
    /// Loops through all Routes with `isNew == true` and sets `isNew` to false
    static func clearNewRoutes() throws {
        let newRoutes = routes(withPredicate: NSPredicate(format: "isNew == true"))

        try autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return
            }
            
            try database.write {
                for route in newRoutes {
                    route.isNew = false
                }
            }
        }
    }
    
    static func routesNear(_ coordinate: CLLocationCoordinate2D, range: CLLocationDistance) -> [Route] {
        let predicate = Predicates.distance(coordinate, span: range * 2, latKey: "firstWaypointLatitude", lonKey: "firstWaypointLongitude")
        return routes(withPredicate: predicate)
    }
    
    static func routesContaining(markerId: String) -> [Route] {
        let predicate = NSPredicate(format: "SUBQUERY(waypoints, $waypoint, $waypoint.markerId == %@).@count > 0", markerId)
        return routes(withPredicate: predicate)
    }
    
    // MARK: Reference Entities
    
    static func containsReferenceEntity(withKey key: String) -> Bool {
        return referenceEntityByKey(key) != nil
    }
    
    static func referenceEntities(with predicate: NSPredicate) -> [ReferenceEntity] {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return []
            }
            
            return Array(database.objects(ReferenceEntity.self).filter(predicate))
        }
    }
    
    ///
    /// Returns reference entity objects where `object.isTemp == isTemp`
    ///
    /// Parameter: isTemp true if the returned objects should be marked as temporary and  false if the returned objects should not be marked as temporary
    ///
    static func referenceEntities(isTemp: Bool = false) -> [ReferenceEntity] {
        return referenceEntities(with: Predicates.isTemporary(isTemp))
    }
    
    static func referenceEntityByKey(_ key: String) -> ReferenceEntity? {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return nil
            }
            
            return database.object(ofType: ReferenceEntity.self, forPrimaryKey: key)
        }
    }
    
    static func referenceEntityByEntityKey(_ key: String) -> ReferenceEntity? {
        return referenceEntities(with: NSPredicate(format: "entityKey = %@", key)).first ?? referenceEntityByKey(key)
    }
    
    ///
    /// Returns reference entity objects near the given coordinate and with the expected `isTemp` value (if expected value is provided)
    ///
    /// Parameters:
    /// - coordinate returns objects near the given coordiante
    /// - isTemp `nil` if objects should not be filtered by `isTemp`,  true if the returned objects should be marked as temporary and  false if the returned objects should not be marked as temporary
    ///
    static func referenceEntityByLocation(_ coordinate: CLLocationCoordinate2D, isTemp: Bool? = false) -> ReferenceEntity? {
        return referenceEntitiesNear(coordinate, range: 1.0, isTemp: isTemp).first
    }
    
    ///
    /// Returns reference entity objects near the given location and with the expected `isTemp` value (if expected value is provided)
    ///
    /// Parameters:
    /// - location returns objects near the given location
    /// - isTemp `nil` if objects should not be filtered by `isTemp`,  true if the returned objects should be marked as temporary and  false if the returned objects should not be marked as temporary
    ///
    static func referenceEntityByGenericLocation(_ location: GenericLocation, isTemp: Bool? = false) -> ReferenceEntity? {
        return referenceEntityByLocation(location.location.coordinate, isTemp: isTemp)
    }
    
    ///
    /// Returns reference entity objects matching the given source and with the expected `isTemp` value (if expected value is provided)
    ///
    /// Parameters:
    /// - source defines what the reference entity is based on
    /// - isTemp `nil` if objects should not be filtered by `isTemp`,  true if the returned objects should be marked as temporary and  false if the returned objects should not be marked as temporary
    ///
    static func referenceEntity(source: LocationDetail.Source, isTemp: Bool? = false) -> ReferenceEntity? {
        var marker: ReferenceEntity?
        
        switch source {
        case .entity(let id): marker = SpatialDataCache.referenceEntityByEntityKey(id)
        case .coordinate(let location): marker = SpatialDataCache.referenceEntityByLocation(location.coordinate, isTemp: isTemp)
        case .designData: marker = nil
        case .screenshots(let poi): marker = SpatialDataCache.referenceEntityByEntityKey(poi.key)
        }
        
        if let isTemp = isTemp, let marker = marker {
            // Only return markers with the given value for `isTemp`
            return marker.isTemp == isTemp ? marker : nil
        } else {
            // Do not filter by `isTemp`
            return marker
        }
    }
    
    ///
    /// Returns reference entity objects near the given coordinate and with the expected `isTemp` value (if expected value is provided)
    ///
    /// Parameters:
    /// - coordinate returns objects near the given coordiante
    /// - range search distance in meters
    /// - isTemp `nil` if objects should not be filtered by `isTemp`,  true if the returned objects should be marked as temporary and  false if the returned objects should not be marked as temporary
    ///
    static func referenceEntitiesNear(_ coordinate: CLLocationCoordinate2D, range: CLLocationDistance, isTemp: Bool? = false) -> [ReferenceEntity] {
        var predicate: NSPredicate
        
        if let isTemp = isTemp {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                Predicates.distance(coordinate, span: range * 2, latKey: "latitude", lonKey: "longitude"),
                Predicates.isTemporary(isTemp)
            ])
        } else {
            predicate = Predicates.distance(coordinate, span: range * 2, latKey: "latitude", lonKey: "longitude")
        }
        
        return referenceEntities(with: predicate)
    }
    
    /// Loops through all ReferenceEntities with `isNew == true` and sets `isNew` to false
    static func clearNewReferenceEntities() throws {
        let newReferenceEntities = referenceEntities(with: NSPredicate(format: "isNew == true"))

        try autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return
            }
            
            try database.write {
                for entity in newReferenceEntities {
                    entity.isNew = false
                }
            }
        }
    }
    
    // MARK: Intersection Entities
    
    static func intersectionEntities(with predicate: NSPredicate) -> [Intersection] {
        return autoreleasepool {
            guard let database = try? RealmHelper.getCacheRealm() else {
                return []
            }
            
            return Array(database.objects(Intersection.self).filter(predicate))
        }
    }
    
    static func intersectionByKey(_ key: String) -> Intersection? {
        return autoreleasepool {
            guard let database = try? RealmHelper.getCacheRealm() else {
                return nil
            }
            
            return database.object(ofType: Intersection.self, forPrimaryKey: key)
        }
    }
    
    /// Returns all the intersections that connect to a given road
    static func intersections(forRoadKey roadKey: String) -> [Intersection]? {
        return intersections(forRoadKey: roadKey, inRegion: nil)
    }
    
    /// Returns all the intersections that connect to a given road
    static func intersection(forRoadKey roadKey: String, atCoordinate coordinate: CLLocationCoordinate2D) -> Intersection? {
        return intersections(forRoadKey: roadKey)?.first(where: { $0.coordinate == coordinate })
    }
    
    /// Returns all the intersections that connect to a given road, within a region.
    static func intersections(forRoadKey roadKey: String, inRegion region: MKCoordinateRegion?) -> [Intersection]? {
        let roadsPredicate = NSPredicate(format: "ANY roadIds.id == '\(roadKey)'")
        
        let predicate: NSPredicate
        
        if let region = region {
            let regionPredicate = NSPredicate(region: region)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [regionPredicate, roadsPredicate])
        } else {
            predicate = roadsPredicate
        }
        
        return intersectionEntities(with: predicate)
    }
    
    // MARK: VectorTile Tools
    
    static func tiles(forDestinations: Bool, forReferences: Bool, at zoomLevel: UInt) -> Set<VectorTile> {
        var tiles: Set<VectorTile> = []
        
        if forReferences {
            let porTiles = SpatialDataCache.tilesForReferenceEntities(at: zoomLevel)
            for porTile in porTiles {
                tiles.insert(porTile)
            }
        }
        
        let manager = AppContext.shared.spatialDataContext.destinationManager
        if forDestinations, let destination = manager.destination {
            tiles.insert(VectorTile(latitude: destination.latitude, longitude: destination.longitude, zoom: zoomLevel))
        }
        
        return tiles
    }
    
    static func tilesForReferenceEntities(at zoomLevel: UInt) -> Set<VectorTile> {
        let referenceEntities = SpatialDataCache.referenceEntities()
        let tiles = referenceEntities.map { VectorTile(latitude: $0.latitude, longitude: $0.longitude, zoom: zoomLevel) }
        return Set(tiles)
    }
    
    static func tileData(for tiles: [VectorTile]) -> [TileData] {
        do {
            let cache = try RealmHelper.getCacheRealm()
            return Array(cache.objects(TileData.self).filter(NSPredicate(format: "quadkey IN %@", tiles.map({ $0.quadKey }))))
        } catch {
            return []
        }
    }
    
    // MARK: POI Type
    
    static func isAddress(poi: POI) -> Bool {
        return poi as? Address != nil
    }
    
    // MARK: Search by POI Characteristic
    
    private static func lastSelectedObjects() -> [POI] {
        let predicate: NSPredicate = Predicates.lastSelectedDate
        
        return objectsFromAllProviders(predicate: predicate)
    }
    
    static func recentlySelectedObjects() -> [POI] {
        let sortPredicate = Sort.lastSelected()
        return SpatialDataCache.lastSelectedObjects().sorted(by: sortPredicate, maxLength: 5)
    }
    
    static func fetchEstimatedCoordinate(address: String, in region: CLRegion? = nil, completionHandler: @escaping (GeocodedAddress?) -> Void) {
        guard let geocoder = geocoder else {
            GDLogSpatialDataError("Geocode Coordinate Error - Geocoder has not been initialized")
            
            completionHandler(nil)
            return
        }
        
        geocoder.geocodeAddressString(address: address, in: region) { (results) in
            guard let results = results  else {
                GDLogSpatialDataError("Geocode Coordinate Error - No results returned")
                
                GDATelemetry.track("geocode.coordinates.error.no_results")
                
                completionHandler(nil)
                return
            }
            
            completionHandler(results.first)
        }
    }
    
    static func fetchEstimatedAddress(location: CLLocation, completionHandler: @escaping (GeocodedAddress?) -> Void) {
        guard let geocoder = geocoder else {
            GDLogSpatialDataError("Geocode Address Error - Geocoder has not been initialized")
            
            completionHandler(nil)
            return
        }
        
        geocoder.geocodeLocation(location: location) { (results) in
            guard let results = results  else {
                GDLogSpatialDataError("Geocode Address Error - No results returned")
                
                completionHandler(nil)
                return
            }
            
            completionHandler(results.first)
        }
    }
    
}
