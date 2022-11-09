//
//  ReferenceEntity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import RealmSwift

enum ReferenceEntityError: Error {
    case entityKeyDoesNotExist
    case entityDoesNotExist
    case cannotCacheEntity
    case cannotAddMarker
}

extension Notification.Name {
    static let markerAdded = Notification.Name("GDAMarkerAdded")
    static let markerRemoved = Notification.Name("GDAMarkerRemoved")
    static let markerUpdated = Notification.Name("GDAMarkerUpdated")
}

class ReferenceEntity: Object, ObjectKeyIdentifiable {
    // MARK: Constants
    
    struct Keys {
        static let entityId = "GDAReferenceEntityID"
    }
    
    // MARK: Properties

    @Persisted(primaryKey: true) var id: String = UUID().uuidString // Primary key
    @Persisted var entityKey: String?
    @Persisted var lastUpdatedDate: Date?
    @Persisted var lastSelectedDate: Date? = Date()
    @Persisted var isNew: Bool = true
    @Persisted var isTemp: Bool = true
    
    @Persisted var latitude: CLLocationDegrees = 0.0
    @Persisted var longitude: CLLocationDegrees = 0.0
    
    @Persisted var nickname: String?
    @Persisted var estimatedAddress: String?
    @Persisted var annotation: String?
    
    private lazy var _poi: POI? = {
        guard let key = entityKey else {
            return nil
        }
        
        return SpatialDataCache.searchByKey(key: key)
    }()
    
    // MARK: Computed Properties
    
    /// CLLocationCoordinate2D for the referenced entity
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// A computed property that returns the "preferred" name of the POI. If the entity
    /// has a nickname, that will be returned, otherwise the given name of the entity
    /// will be returned
    var name: String {
        if let nickname = nickname {
            return nickname
        }
        
        return givenLocalizedName
    }
    
    /// The "given" name of an entity is the name attached to the underlying POI object
    var givenLocalizedName: String {
        return getPOI().localizedName
    }
    
    /// The address of an entity returns the known address of the underlying POI if
    /// it exists, or the estimated address of the reference otherwise.
    var address: String {
        let estimated = estimatedAddress != nil ? GDLocalizedString("directions.near_name", estimatedAddress!) : GDLocalizedString("directions.unknown_address")
        
        if entityKey == nil {
            return estimated
        }
        
        // If the reference entity has an entity key, but we can't find that entity, it is most likely an address
        // object that was somehow deleted. In that case, return the estimated address as if it were the actual address...
        guard let entity = _poi else {
            return estimatedAddress != nil ? estimatedAddress! : GDLocalizedString("directions.unknown_address")
        }
        
        return entity.addressLine ?? estimated
    }
    
    /// Address string that should be used when displaying this reference entity on screen
    var displayAddress: String {
        // If the nickname is different from the given name (and the underlying POI isn't an Address), prepend the address with the given name.
        if name != givenLocalizedName && !address.localizedCaseInsensitiveContains(givenLocalizedName) && !(getPOI() is Address) {
            return "\(givenLocalizedName)\n\(address)"
        }
        
        return address
    }
    
    // MARK: Initialization
    
    /// Reference Entity initializer.
    ///
    /// - Parameters:
    ///   - entityKey: Primary key of the backing POI for this reference entity
    ///   - coordinate: The lat/lon of the reference entity. This parameter is used for re-caching the backing POI information if the cached data is deleted but the reference entity is not.
    ///   - name: Optional nickname for the reference entity
    convenience init(coordinate: CLLocationCoordinate2D, entityKey: String? = nil, name: String? = nil, estimatedAddress: String? = nil, annotation: String? = nil, temp: Bool = false) {
        self.init()
        
        // Set entity
        self.entityKey = entityKey
        
        // Set location info for re-caching
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        
        // Set the nickname
        if let name = name, name.isEmpty == false {
            nickname = name
        } else {
            nickname = nil
        }
        
        // Set the estimated address from the generic location
        if let estimatedAddress = estimatedAddress, estimatedAddress.isEmpty == false {
            self.estimatedAddress = estimatedAddress
        } else {
            self.estimatedAddress = nil
        }
        
        // Set the annotation
        if let annotation = annotation, annotation.isEmpty == false {
            self.annotation = annotation
        } else {
            self.annotation = nil
        }
        
        // Set temporary status
        isTemp = temp
    }
    
    convenience init(location: GenericLocation, name: String? = nil, estimatedAddress: String? = nil, annotation: String? = nil, temp: Bool = false) {
        self.init()
        
        // Set location info for re-caching
        latitude = location.latitude
        longitude = location.longitude
        
        // Set the nickname
        if let name = name, name.isEmpty == false {
            nickname = name
        } else {
            nickname = nil
        }
        
        // Set the estimated address from the generic location
        if let estimatedAddress = estimatedAddress, estimatedAddress.isEmpty == false {
            self.estimatedAddress = estimatedAddress
        } else {
            self.estimatedAddress = nil
        }
        
        if let annotation = annotation, annotation.isEmpty == false {
            self.annotation = annotation
        } else {
            self.annotation = nil
        }
        
        // Set temporary status
        isTemp = temp
    }
    
    convenience init?(markerParameters: MarkerParameters, entity: POI) {
        guard let id = markerParameters.id else { return nil }
        
        self.init()

        self.id = id
        self.entityKey = entity.key
        self.isNew = true
        self.isTemp = false
        
        self.latitude = markerParameters.location.coordinate.latitude
        self.longitude = markerParameters.location.coordinate.longitude
        
        if let nickname = markerParameters.nickname, nickname.isEmpty == false {
            self.nickname = nickname
        } else {
            self.nickname = nil
        }
        
        if let estimatedAddress = markerParameters.estimatedAddress, estimatedAddress.isEmpty == false {
            self.estimatedAddress = estimatedAddress
        } else {
            self.estimatedAddress = nil
        }
        
        if let annotation = markerParameters.annotation, annotation.isEmpty == false {
            self.annotation = annotation
        } else {
            self.annotation = nil
        }
    }
    
    // MARK: Methods
    
    /// Helper method for calculating the distance from this ReferenceEntity to
    /// another coordinate.
    ///
    /// - Parameter from: The other location
    /// - Returns: Distance to the other location
    func distanceToClosestLocation(from location: CLLocation) -> CLLocationDistance {
        if let poi = _poi {
            return poi.distanceToClosestLocation(from: location)
        }
        
        return self.coordinate.distance(from: location.coordinate)
    }
    
    /// Bearing from the entity to the user's location
    ///
    /// - Parameter to: The user's location
    /// - Returns: Bearing from the entity to the user's location
    func bearingToClosestLocation(from location: CLLocation) -> CLLocationDirection {
        if let poi = _poi {
            return poi.bearingToClosestLocation(from: location)
        }
        
        return location.coordinate.bearing(to: coordinate)
    }
    
    /// Helper method for calculating the closest location on the underlying POI for this
    /// ReferenceEntity. Uses entrances on the entity if any exist.
    ///
    /// - Parameter location: The user's location
    /// - Returns: Closest location on the ReferenceEntity
    func closestLocation(from location: CLLocation) -> CLLocation {
        if let poi = _poi {
            return poi.closestLocation(from: location, useEntranceIfAvailable: true)
        }
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// Gets the POI for the reference entity.
    ///
    /// - Returns: A POI referenced by this ReferenceEntity
    func getPOI() -> POI {
        return _poi ?? GenericLocation(ref: self)
    }
    
    /// Updates the lastSelectedDate of the reference entity and, if the reference entity is not a
    /// generic location, the lastSelectedDate of the underlying POI type in the cache.
    ///
    /// - Parameter date: Date to set
    /// - Throws: If the realms cannot be accessed or the update cannot be committed
    func updateLastSelectedDate(to date: Date = Date()) throws {
        let database = try RealmHelper.getDatabaseRealm()
        
        try database.write {
            self.lastSelectedDate = date
        }
        
        if let entity = getPOI() as? Object {
            let cache = try RealmHelper.getCacheRealm()
            
            try cache.write {
                entity[POI.Keys.lastSelectedDate] = date
            }
        }
        
        ReferenceEntity.notifyEntityUpdated(id)
    }
    
    func setTemporary(_ flag: Bool) throws {
        let database = try RealmHelper.getDatabaseRealm()
        
        let newFlag = self.isTemp && !flag
        try database.write {
            self.isTemp = flag
            self.isNew = newFlag
        }
        
        ReferenceEntity.notifyEntityUpdated(id)
    }
    
    // MARK: Static Methods
    
    static func add(detail: LocationDetail, telemetryContext: String?, isTemporary: Bool = false, notify: Bool = true) throws -> String {
        if let id = detail.markerId, let marker = SpatialDataCache.referenceEntityByKey(id) {
            try update(entity: marker, location: detail.location.coordinate, nickname: detail.nickname, address: detail.estimatedAddress, annotation: detail.annotation, context: telemetryContext, isTemp: isTemporary)
            
            return id
        }
        
        switch detail.source {
        case .coordinate(let at):
            let location = GenericLocation(lat: at.coordinate.latitude, lon: at.coordinate.longitude)
            return try add(location: location, nickname: detail.nickname, estimatedAddress: detail.estimatedAddress, annotation: detail.annotation, temporary: isTemporary, context: telemetryContext, notify: notify)
        case .entity(let id):
            return try add(entityKey: id, nickname: detail.nickname, estimatedAddress: detail.estimatedAddress, annotation: detail.annotation, temporary: isTemporary, context: telemetryContext, notify: notify)
        case .designData:
            throw ReferenceEntityError.cannotAddMarker
        case .screenshots:
            throw ReferenceEntityError.cannotAddMarker
        }
    }
        
    /// Constructs and saves a reference point with the POI referred to by the supplied
    /// entity key. A nickname can optionally be set for the new reference entity. If the
    /// entityKey parameter corresponds to an Address entity, the estimatedAddress property
    /// will be ignored in favor of the actual address.
    ///
    /// - Parameters:
    ///   - entityKey: key of the underlying POI this reference entity refers to
    ///   - nickname: nickname of the reference entity
    ///   - estimatedAddress: estimated address of the reference entity
    ///   - temporary: flag indicating if the new reference entity is temporary (an audio beacon) or not
    /// - Returns: ID of the new reference point
    /// - Throws: If the database/cache cannot be accessed or the new reference entity cannot be added
    static func add(entityKey: String, nickname: String? = nil, estimatedAddress: String? = nil, annotation: String? = nil, temporary: Bool = false, context: String? = nil, notify: Bool = true) throws -> String {
        return try autoreleasepool {
            let database = try RealmHelper.getDatabaseRealm()
            let cache = try RealmHelper.getCacheRealm()
            
            if let existingMarker = SpatialDataCache.referenceEntityByEntityKey(entityKey) {
                // Update and return the existing marker
                try update(entity: existingMarker, nickname: nickname, address: estimatedAddress, annotation: annotation, context: context, isTemp: temporary)
                
                return existingMarker.id
            }
            
            guard let entity = SpatialDataCache.searchByKey(key: entityKey) else {
                // Return if entity does not exist (or doesn't exist in Realm)
                throw ReferenceEntityError.entityDoesNotExist
            }
            
            // In the case that the new entity is an address, backup the address in the estimated address
            // field of the Reference Entity
            var addr = estimatedAddress
            if let addrEntity = entity as? Address {
                addr = addrEntity.addressLine
            }
            
            // Add reference entity
            let reference = ReferenceEntity(coordinate: entity.centroidCoordinate,
                                            entityKey: entityKey,
                                            name: nickname,
                                            estimatedAddress: addr,
                                            annotation: annotation,
                                            temp: temporary)
            reference.lastUpdatedDate = Date()

            // Set the last selected date on the POI
            if let rlmEntity = entity as? Object {
                try cache.write {
                    rlmEntity[POI.Keys.lastSelectedDate] = reference.lastSelectedDate
                }
            }
            
            try database.write {
                database.add(reference, update: .modified)
            }
            
            if !temporary {
                AppContext.shared.cloudKeyValueStore.store(referenceEntity: reference)
                
                let includesAnnotation = annotation?.isEmpty ?? true ? "false" : "true"
                
                if entity is Address {
                    GDATelemetry.track("markers.added", with: ["type": "address", "includesAnnotation": includesAnnotation, "context": context ?? "none"])
                    GDATelemetry.helper?.markerCountAddress += 1
                } else {
                    GDATelemetry.track("markers.added", with: ["type": "poi", "includesAnnotation": includesAnnotation, "context": context ?? "none"])
                    GDATelemetry.helper?.markerCountPOI += 1
                }
                
                NSUserActivity(userAction: .saveMarker).becomeCurrent()
            }
            
            if notify {
                notifyEntityAdded(reference.id)
            }
            
            return reference.id
        }
    }
    
    /// Updates the given reference entity
    ///
    /// - Parameters:
    ///   - entity: The reference entity to update
    ///   - nickname: Nickname for the reference entity (required since this reference doesn't refer to an underlying POI object)
    ///   - estimatedAddress: estimated address of the reference entity
    ///   - annotation: annotation of the reference entity
    ///   - isTemp: `true` if the reference entity is temporary (e.g. audio beacon), otherwise `false`
    /// - Throws: If the database/cache cannot be accessed or the new reference entity cannot be added
    static func update(entity: ReferenceEntity, location: CLLocationCoordinate2D? = nil, nickname: String?, address: String?, annotation: String?, context: String? = nil, isTemp: Bool) throws {
        var locChanged: Bool = false
        if let loc = location, loc != entity.coordinate {
            locChanged = true
        }
        
        if entity.nickname == nickname, entity.estimatedAddress == address, entity.annotation == annotation, entity.isTemp == isTemp, !locChanged {
            // There is nothing to update
            return
        }
        
        let now = Date()
        
        var updatedNickname = nickname
        if locChanged, nickname == nil {
            // Because the location has changed, we are going to disconnect this marker from its
            // underlying POI and use a generic location instead. In the edge case where no nickname
            // has been specified, make sure we at least keep the underlying POI's name.
            updatedNickname = entity.getPOI().localizedName
        }
        
        try autoreleasepool {
            let database = try RealmHelper.getDatabaseRealm()
            
            let previousIsTemp = entity.isTemp
            
            try database.write {
                // If the location was changed, then remove ref to the underlying POI (if one exists), and store
                // the new location
                if locChanged, let loc = location {
                    entity.entityKey = nil
                    entity.latitude = loc.latitude
                    entity.longitude = loc.longitude
                }
                
                // Ensure the nickname is not empty and is not the same as the given name
                entity.nickname = updatedNickname
                
                // If an address was provided, update it
                if let addressLine = address, addressLine.isEmpty == false {
                    entity.estimatedAddress = addressLine
                }
                
                if let annotation = annotation, annotation.isEmpty == false {
                    entity.annotation = annotation
                } else {
                    entity.annotation = nil
                }
                
                entity.isTemp = isTemp
                // If the marker is temporary, do not set the `isNew` flag
                // If the marker was previously temporary, set the `isNew` flag
                entity.isNew = isTemp ? false : previousIsTemp
                
                entity.lastUpdatedDate = now
            }
            
            // Update the lastSelectedDate to support recents
            try entity.updateLastSelectedDate(to: now)
            
            AppContext.shared.cloudKeyValueStore.update(referenceEntity: entity)
            
            let includesAnnotation = annotation?.isEmpty ?? true ? "false" : "true"
            GDATelemetry.track("markers.edited", with: ["includesAnnotation": includesAnnotation, "context": context ?? "none"])
            
            ReferenceEntity.notifyEntityUpdated(entity.id)
            
            if locChanged {
                // Update all routes whose first waypoint is the given entity
                try Route.updateWaypointInAllRoutes(markerId: entity.id)
            }
        }
    }
    
    /// Constructs and saves a reference point for the generic location described by the
    /// provided coordinate and nickname.
    ///
    /// - Parameters:
    ///   - coordinate: Location of the reference entity
    ///   - nickname: Nickname for the reference entity (required since this reference doesn't refer to an underlying POI object)
    ///   - estimatedAddress: estimated address of the reference entity
    ///   - temporary: flag indicating if the new reference entity is temporary (an audio beacon) or not
    /// - Returns: ID of the new reference point
    /// - Throws: If the database/cache cannot be accessed or the new reference entity cannot be added
    static func add(location: GenericLocation, nickname: String? = nil, estimatedAddress: String? = nil, annotation: String? = nil, temporary: Bool = false, context: String? = nil, notify: Bool = true) throws -> String {
        return try autoreleasepool {
            let database = try RealmHelper.getDatabaseRealm()
            
            // If an existing marker is found at the same location, then return that marker's id. In the case that
            // `existingFlag.isTemp` matches `temporary`, then we can also update the underlying marker in case any
            // of it's info has changed. If `existingFlag.isTemp` is false, `temporary` is true, and all other properties
            // match, then we can also update the marker to set `isTemp` to false. This covers the only edge case where
            // we allow permanent markers to become temporary: when a marker is deleted and there is currently a beacon
            // set on the location of that marker.
            if let existingMarker = SpatialDataCache.referenceEntityByGenericLocation(location, isTemp: nil) {
                let tempStatusMatches = existingMarker.isTemp == temporary
                let propertiesMatch = existingMarker.nickname == nickname &&
                                      existingMarker.estimatedAddress == estimatedAddress &&
                                      existingMarker.annotation == annotation
                let shouldDowngradeMarker = !existingMarker.isTemp && temporary && propertiesMatch
                
                if tempStatusMatches || shouldDowngradeMarker {
                    try update(entity: existingMarker, nickname: nickname, address: estimatedAddress, annotation: annotation, context: context, isTemp: temporary)
                }
                
                return existingMarker.id
            }
            
            var name: String?
            
            if let nickname = nickname, nickname.isEmpty == false {
                name = nickname
            } else {
                name = location.name
            }
            
            let address: String?
            
            // If an address was provided by the generic location, use it
            if let addressLine = location.addressLine, addressLine.isEmpty == false {
                address = addressLine
            } else {
                address = estimatedAddress
            }
            
            let reference = ReferenceEntity(location: location, name: name, estimatedAddress: address, annotation: annotation, temp: temporary)
            reference.lastUpdatedDate = Date()
            
            try database.write {
                database.add(reference, update: .modified)
            }
            
            if !temporary {
                AppContext.shared.cloudKeyValueStore.store(referenceEntity: reference)
                
                let includesAnnotation = annotation?.isEmpty ?? true ? "false" : "true"
                GDATelemetry.track("markers.added", with: ["type": "generic_location", "includesAnnotation": includesAnnotation, "context": context ?? "none"])
                GDATelemetry.helper?.markerCountLocation += 1
                
                NSUserActivity(userAction: .saveMarker).becomeCurrent()
            }
            
            if notify {
                notifyEntityAdded(reference.id)
            }
            
            return reference.id
        }
    }
    
    private static func notifyEntityAdded(_ id: String) {
        DispatchQueue.main.async {
            AppContext.process(MarkerAddedEvent(id))
            
            NotificationCenter.default.post(name: Notification.Name.markerAdded, object: self, userInfo: [ReferenceEntity.Keys.entityId: id])
        }
    }
    
    private static func notifyEntityUpdated(_ id: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .markerUpdated, object: self, userInfo: [Keys.entityId: id])
        }
    }
    
    private static func notifyEntityRemoved(_ id: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .markerRemoved, object: self, userInfo: [Keys.entityId: id])
        }
    }
    
    /// Removes the reference entity with the corresponding ID. If the reference entity is currently set as the
    /// destination, it is set as a temporary entity instead of completely removing it.
    ///
    /// - Parameter id: ID of the reference entity to remove
    /// - Throws: If the database/cache cannot be accessed or no reference entity exists for the provided ID
    static func remove(id: String) throws {
        if let destination = AppContext.shared.spatialDataContext.destinationManager.destination, destination.id == id {
            try destination.setTemporary(true)
            ReferenceEntity.notifyEntityRemoved(id)
            return
        }
        
        let database = try RealmHelper.getDatabaseRealm()
        
        guard let entity = database.object(ofType: ReferenceEntity.self, forPrimaryKey: id) else {
            return
        }
        
        // If the marker doesn't have an underlying entity it refers to, remove from the
        // callout history so there isn't an empty card in the history
        if entity.entityKey == nil {
            AppContext.shared.calloutHistory.remove { (callout) -> Bool in
                if let callout = callout as? POICallout, let calloutMarker = callout.marker {
                    return calloutMarker.id == entity.id
                }
                
                return false
            }
        }
        
        // Remove the marker from corresponding routes
        try Route.removeWaypointFromAllRoutes(markerId: id)
        
        AppContext.shared.cloudKeyValueStore.remove(referenceEntity: entity)
        
        try database.write {
            database.delete(entity)
        }
        
        GDATelemetry.track("markers.removed")
        GDATelemetry.helper?.markerCountRemoved += 1
        
        ReferenceEntity.notifyEntityRemoved(id)
    }
    
    /// Removes all reference entities. Because the destination is a marker, this also clears the destination.
    ///
    /// - Throws: If the database/cache cannot be accessed or any reference entity cannot be removed
    static func removeAll() throws {
        // Remove the destination
        try AppContext.shared.spatialDataContext.destinationManager.clearDestination(logContext: "settings.clear_cache")
        
        let database = try RealmHelper.getDatabaseRealm()
        
        // There is no code to remove corresponding route waypoints
        // because `ReferenceEntity.removeAll` is only called from `StatusTableViewController`
        // which separately calls `Route.deleteAll`
        
        for entity in database.objects(ReferenceEntity.self) {
            let id = entity.id
            
            AppContext.shared.cloudKeyValueStore.remove(referenceEntity: entity)
            
            try database.write {
                database.delete(entity)
                
                GDATelemetry.track("markers.removed")
                GDATelemetry.helper?.markerCountRemoved += 1
                
                ReferenceEntity.notifyEntityRemoved(id)
            }
        }
    }
    
    /// Removes all temporary reference entities.
    ///
    /// - Throws: If the database/cache cannot be accessed or any reference entity cannot be removed
    static func removeAllTemporary() throws {
        let database = try RealmHelper.getDatabaseRealm()
        
        for entity in database.objects(ReferenceEntity.self).filter("isTemp == true") {
            try database.write {
                database.delete(entity)
            }
        }
    }
    
    static func deleteActionMake(id: String, deleted: (() -> Void)? = nil, canceled: (() -> Void)? = nil) -> UIAlertController {
        // Create the action buttons for the alert.
        let deleteAction = UIAlertAction(title: GDLocalizedString("general.alert.delete"), style: .destructive) { (_) in
            do {
                try ReferenceEntity.remove(id: id)
            } catch {
                GDLogAppError("Unable to successfully delete the reference entity (id: \(id))")
            }
            
            deleted?()
        }
        
        let cancelAction = UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel) { (_) in
            canceled?()
        }
        
        // Create and configure the alert controller.
        let alert = UIAlertController(title: GDLocalizedString("markers.destructive_delete_message"),
                                      message: GDLocalizedString("general.alert.destructive_undone_message"),
                                      preferredStyle: .alert)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        return alert
    }
    
    static func objectKeys(sortedBy: SortStyle) -> [String] {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return []
            }
            
            switch sortedBy {
            case .alphanumeric:
                return database.objects(ReferenceEntity.self)
                    .filter("isTemp == false")
                    .map({ entity -> (ref: ReferenceEntity, name: String) in
                        return (ref: entity, name: entity.name)
                    })
                    .sorted(by: { $0.name < $1.name })
                    .compactMap({ $0.ref.id })
                
            case .distance:
                let loc = AppContext.shared.geolocationManager.location ?? CLLocation(latitude: 0.0, longitude: 0.0)
                
                return database.objects(ReferenceEntity.self)
                    .filter("isTemp == false")
                    .map({ entity -> (ref: ReferenceEntity, dist: CLLocationDistance) in
                        return (ref: entity, dist: entity.distanceToClosestLocation(from: loc))
                    })
                    .sorted(by: { $0.dist < $1.dist })
                    .compactMap({ $0.ref.id })
            }
        }
    }
    
    static func cleanCorruptEntities() throws {
        try autoreleasepool {
            let entities = try RealmHelper.getDatabaseRealm().objects(ReferenceEntity.self).filter("isTemp == false")
            
            for ref in entities where ref.nickname == nil && ref._poi == nil {
                // If the backing POI doesn't exist and this isn't a generic location (no nickname), remove the POR
                try ReferenceEntity.remove(id: ref.id)
            }
        }
    }
}
