//
//  LocationDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import CocoaLumberjackSwift
import SwiftUI

struct LocationDetail {
    
    enum Source: Equatable {
        
        case entity(id: String)
        case coordinate(at: CLLocation)
        case designData(at: CLLocation, address: String)
        case screenshots(poi: GenericLocation)
        
        fileprivate var entity: POI? {
            if case .entity(let id) = self {
                return SpatialDataCache.searchByKey(key: id)
            } else if case .screenshots(let poi) = self {
                return poi
            }
            
            return nil
        }
        
        var name: String? {
            return entity?.localizedName
        }
        
        var address: String? {
            if case let .designData(_, address) = self {
                return address
            }
            
            return entity?.addressLine
        }
        
        var isCachingEnabled: Bool {
            // If the data source does not allow caching, return false
            // For OSM, return true
            return true
        }
        
        func closestLocation(from userLocation: CLLocation, useEntranceIfAvailable: Bool = true) -> CLLocation? {
            switch self {
            case .entity:
                return entity?.closestLocation(from: userLocation, useEntranceIfAvailable: useEntranceIfAvailable)
                
            case .coordinate(let location):
                return location
                
            case .designData(let location, _):
                return location
                
            case .screenshots(let poi):
                return poi.location
            }
        }
        
        static func == (lhs: Source, rhs: Source) -> Bool {
            switch lhs {
            case .entity(let lhsId):
                guard case .entity(let rhsId) = rhs else {
                    return false
                }
                
                return lhsId == rhsId
            case .coordinate(let lhsAt):
                guard case .coordinate(let rhsAt) = rhs else {
                    return false
                }
                
                return lhsAt.coordinate == rhsAt.coordinate
                
            case let .designData(lhsAt, lhsAddress):
                guard case let .designData(rhsAt, rhsAddress) = rhs else {
                    return false
                }
                
                return lhsAt.coordinate == rhsAt.coordinate && lhsAddress == rhsAddress
                
            case let .screenshots(lhsPoi):
                guard case let .screenshots(rhsPoi) = rhs else {
                    return false
                }
                
                return lhsPoi.location.coordinate == rhsPoi.location.coordinate && lhsPoi.name == rhsPoi.name && lhsPoi.addressLine == rhsPoi.addressLine
            }
        }
        
    }
    
    // MARK: Properties
    
    let source: Source
    let location: CLLocation
    let centerLocation: CLLocation
    let telemetryContext: String?
    
    // Estimated Properties
    private let estimated: EstimatedLocationDetail?
    // Imported Properties
    private let imported: ImportedLocationDetail?
    
    // Marker Properties
    
    var markerId: String? {
        // Ignore temporary markers (e.g., beacons)
        guard let marker = marker, marker.isTemp == false else {
            return nil
        }
        
        return marker.id
    }
    
    var isMarker: Bool {
        return markerId != nil
    }
    
    var beaconId: String? {
        guard let marker = marker else {
            return nil
        }
        
        guard AppContext.shared.spatialDataContext.destinationManager.destinationKey == marker.id else {
            return nil
        }
        
        return marker.id
    }
    
    var isBeacon: Bool {
        return beaconId != nil
    }
    
    private var marker: ReferenceEntity? {
        // Search for markers (including temporary markers) at the given location
        return SpatialDataCache.referenceEntity(source: source, isTemp: nil)
    }
    
    // Name Properties
    
    var nickname: String? {
        if let imported = imported {
            // If a new nickname was imported (e.g. univeral link), use it
            // It is possible for this value to be `nil`
            return imported.nickname
        }
        
        if let nickname = marker?.nickname, nickname.isEmpty == false {
            return nickname
        }
        
        return nil
    }
    
    private var name: String? {
        if let name = nickname, name.isEmpty == false {
            return name
        }
        
        if let name = source.name, name.isEmpty == false {
            return name
        }
        
        return nil
    }
    
    var displayName: String {
        if let name = name, name.isEmpty == false {
            return name
        }
        
        if let name = estimated?.name, name.isEmpty == false {
            // If a name does not exist, return an
            // estimated value
            return name
        }
        
        return GDLocalizedString("location")
    }
    
    var hasName: Bool {
        return name != nil
    }
    
    // Address Properties
    
    var estimatedAddress: String? {
        if let estimatedAddress = marker?.estimatedAddress, estimatedAddress.isEmpty == false {
            // If an estimated address has already been saved
            // with the marker, return it
            return estimatedAddress
        }
        
        if let estimatedAddress = estimated?.address, estimatedAddress.isEmpty == false {
            return estimatedAddress
        }
        
        return nil
    }
    
    private var address: String? {
        if let address = source.address, address.isEmpty == false {
            return address
        }
        
        if let address = estimatedAddress, address.isEmpty == false {
            return GDLocalizedString("directions.near_name", address)
        }
        
        return nil
    }
    
    var displayAddress: String {
        if let address = address {
            return address
        }
        
        // When an address is not provided, return a
        // default value
        return GDLocalizedString("location_detail.default.address")
    }
    
    var hasAddress: Bool {
        return address != nil
    }
    
    // Annotation Properties
    
    var annotation: String? {
        if let imported = imported {
            // If a new annotation was imported (e.g. univeral link), use it
            // It is possible for this value to be `nil`
            return imported.annotation
        }
        
        if let annotation = marker?.annotation, annotation.isEmpty == false {
            return annotation
        }
        
        return nil
    }
    
    var displayAnnotation: String {
        if let annotation = annotation {
            return annotation
        }
        
        // When an annotation is not provided, return a
        // default value
        return GDLocalizedString("location_detail.default.annotation")
    }
    
    // MARK: Waypoint Properties
    
    var departureCallout: String? {
        return imported?.departureCallout
    }
    
    var arrivalCallout: String? {
        return imported?.arrivalCallout
    }
    
    var images: [ActivityWaypointImage]? {
        return imported?.images
    }
    
    var hasImages: Bool {
        guard let images = images else {
            return false
        }
        
        return images.count > 0
    }
    
    var audio: [ActivityWaypointAudioClip]? {
        return imported?.audio
    }
    
    var hasAudio: Bool {
        guard let audio = audio else {
            return false
        }
        
        return audio.count > 0
    }
    
    // MARK: Private Initializers
    
    private init(value: LocationDetail, newLocation: CLLocation) {
        let source = value.source
        let centerLocation = value.centerLocation
        let estimated = value.estimated
        let imported = value.imported
        let telemetryContext = value.telemetryContext
        
        self.init(source: source, location: newLocation, centerLocation: centerLocation, estimated: estimated, imported: imported, telemetryContext: telemetryContext)
    }
    
    private init(value: LocationDetail, estimated: EstimatedLocationDetail, telemetryContext: String?) {
        let source = value.source
        let location = value.location
        let centerLocation = value.centerLocation
        let imported = value.imported
        
        self.init(source: source, location: location, centerLocation: centerLocation, estimated: estimated, imported: imported, telemetryContext: telemetryContext)
    }
    
    private init(source: Source, location: CLLocation, centerLocation: CLLocation, estimated: EstimatedLocationDetail?, imported: ImportedLocationDetail?, telemetryContext: String?) {
        self.source = source
        self.location = location
        self.centerLocation = centerLocation
        self.estimated = estimated
        self.imported = imported
        self.telemetryContext = telemetryContext
    }
    
    // MARK: Realm
    
    func updateLastSelectedDate() {
        DispatchQueue.main.async {
            do {
                if let marker = self.marker {
                    try marker.updateLastSelectedDate()
                } else if var entity = self.source.entity as? SelectablePOI {
                    try autoreleasepool {
                        let cache = try RealmHelper.getCacheRealm()
                         
                        try cache.write {
                            entity.lastSelectedDate = Date()
                        }
                    }
                }
            } catch {
                DDLogError("Failed to update last selected date in Realm")
            }
        }
    }
    
}

// MARK: Public Initializers

extension LocationDetail {
    
    init(marker: ReferenceEntity, imported: ImportedLocationDetail? = nil, telemetryContext: String? = nil) {
        self.init(entity: marker.getPOI(), imported: imported, telemetryContext: telemetryContext)
    }
    
    init?(markerId: String, imported: ImportedLocationDetail? = nil, telemetryContext: String? = nil) {
        guard let marker = SpatialDataCache.referenceEntityByKey(markerId) else {
            return nil
        }
        
        self.init(marker: marker, imported: imported, telemetryContext: telemetryContext)
    }
    
    init(location: CLLocation, imported: ImportedLocationDetail? = nil, telemetryContext: String? = nil) {
        let source: Source = .coordinate(at: location)
        self.init(source: source, location: location, centerLocation: location, estimated: nil, imported: imported, telemetryContext: telemetryContext)
    }
    
    init(entity: POI, imported: ImportedLocationDetail? = nil, telemetryContext: String? = nil) {
        if let entity = entity as? GenericLocation {
            self.init(location: entity.location, imported: imported, telemetryContext: telemetryContext)
        } else {
            let source: Source = .entity(id: entity.key)
            let location: CLLocation
            let centerLocation = entity.centroidLocation
            
            if let userLocation = AppContext.shared.geolocationManager.location {
                location = entity.closestLocation(from: userLocation)
            } else {
                location = entity.centroidLocation
            }
            
            self.init(source: source, location: location, centerLocation: centerLocation, estimated: nil, imported: imported, telemetryContext: telemetryContext)
        }
    }
    
    init?(entityId: String, imported: ImportedLocationDetail? = nil, telemetryContext: String? = nil) {
        guard let entity = SpatialDataCache.searchByKey(key: entityId) else {
            return nil
        }
        
        self.init(entity: entity, imported: imported, telemetryContext: telemetryContext)
    }
    
    init?(designTimeSource: LocationDetail.Source, imported: ImportedLocationDetail? = nil, telemetryContext: String? = nil) {
        guard case let .designData(location, _) = designTimeSource else {
            return nil
        }
        
        self.init(source: designTimeSource, location: location, centerLocation: location, estimated: nil, imported: imported, telemetryContext: telemetryContext)
    }
    
    /// Used for updating an existing marker to a new location. Preserves the name and annotation from the original location, but the address
    /// should be fetched again using `fetchNameAndAddressIfNeeded(for:completion:)`
    ///
    /// - Parameters:
    ///   - original: The original `LocationDetail`
    ///   - location: The new location of the marker
    init(_ original: LocationDetail, withUpdatedLocation location: CLLocation) {
        let source: LocationDetail.Source = .coordinate(at: location)
        let imported = ImportedLocationDetail(nickname: original.name, annotation: original.annotation)
        let telemetryContext = original.telemetryContext
        
        self.init(source: source, location: location, centerLocation: location, estimated: nil, imported: imported, telemetryContext: telemetryContext)
    }
    
    static func fetchNameAndAddressIfNeeded(for value: LocationDetail, completion: @escaping (LocationDetail) -> Void) {
        guard value.name == nil || value.address == nil else {
            // `name` and `address` are already
            // provided
            completion(value)
            return
        }
        
        EstimatedLocationDetail.make(for: value) { (estimatedValue) in
            let newValue = LocationDetail(value: value, estimated: estimatedValue, telemetryContext: value.telemetryContext)
            completion(newValue)
        }
    }
    
    static func updateLocationIfNeeded(for value: LocationDetail) -> LocationDetail {
        guard let entity = value.source.entity else {
            // no-op
            return value
        }
        
        guard let userLocation = AppContext.shared.geolocationManager.location else {
            // no-op
            return value
        }
        
        let newLocation = entity.closestLocation(from: userLocation)
        return LocationDetail(value: value, newLocation: newLocation)
    }
    
}
