//
//  CloudKeyValueStore+Markers.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// MARK: Storing Reference Entities

/// Each reference entity is stored in the cloud key value store as it's own top-level object.
/// This should minimize risk of data loss when using a top level array that contain all objects.
extension CloudKeyValueStore {
    
    // Types
    
    typealias CompletionHandler = (() -> Void)?
    
    // MARK: Constants
    
    /// Marker objects will be top-level key-value objects with a key format of "marker.object_id"
    private static let markerKeyPrefix = "marker"
    
    // MARK: Containment
    
    private var markerKeys: [String] {
        return allKeys.filter { $0.hasPrefix(CloudKeyValueStore.markerKeyPrefix) }
    }
    
    private var markerParametersObjects: [MarkerParameters] {
        return markerKeys.compactMap { markerParameters(forKey: $0) }
    }
    
    private func markerParameters(forKey key: String) -> MarkerParameters? {
        guard let data = object(forKey: key) as? Data else { return nil }
        
        let decoder = JSONDecoder()
        let markerParameters: MarkerParameters
        do {
            markerParameters = try decoder.decode(MarkerParameters.self, from: data)
        } catch {
            GDLogCloudInfo("Could not decode marker with with key: \(key)")
            return nil
        }
        
        return markerParameters
    }
    
    // MARK: Individual Set/Get
    
    /// Returns "marker.object_id"
    private static func key(for referenceEntity: ReferenceEntity) -> String {
        return CloudKeyValueStore.markerKeyPrefix + "." + referenceEntity.id
    }
    
    /// Returns "object_id" from "marker.object_id"
    private static func id(for referenceEntityKey: String) -> String {
        return referenceEntityKey.replacingOccurrences(of: CloudKeyValueStore.markerKeyPrefix + ".", with: "")
    }
    
    func store(referenceEntity: ReferenceEntity) {
        if let markerParameters = MarkerParameters(marker: referenceEntity) {
            let encoder = JSONEncoder()
            let data: Data
            
            do {
                data = try encoder.encode(markerParameters)
            } catch {
                GDLogCloudInfo("Could not encode marker with id: \(markerParameters.id ?? "none"), nickname: \(markerParameters.nickname ?? "none")")
                return
            }
            
            set(object: data, forKey: CloudKeyValueStore.key(for: referenceEntity))
        } else {
            GDLogCloudInfo("Failed to initialize marker parameters")
            GDATelemetry.track("marker_backup.error.parameters_failed_to_initialize")
        }
    }
    
    func update(referenceEntity: ReferenceEntity) {
        // For iCloud key-value store we override the current value
        store(referenceEntity: referenceEntity)
    }
    
    func remove(referenceEntity: ReferenceEntity) {
        removeObject(forKey: CloudKeyValueStore.key(for: referenceEntity))
    }
    
    // MARK: Bulk Set/Get
    
    func syncReferenceEntities(reason: CloudKeyValueStoreChangeReason, changedKeys: [String]? = nil, completion: CompletionHandler = nil) {
        // Importing
        importChanges(changedKeys: changedKeys) { [weak self] in
            // Exporting
            if reason == .initialSync || reason == .accountChanged {
                self?.store()
            }
            
            completion?()
        }
    }
    
    private func importChanges(changedKeys: [String]? = nil, completion: CompletionHandler = nil) {
        var markerParametersObjects = self.markerParametersObjects
        
        // If there are changed keys, we only add/update those objects.
        // If there no changed keys, such as an initial sync or account change we add/update all objects.
        if let changedKeys = changedKeys {
            // Discard irrelevant keys
            var changedKeys = changedKeys.filter { $0.hasPrefix(CloudKeyValueStore.markerKeyPrefix) }
            
            // Discard deleted keys
            changedKeys = changedKeys.filter { allKeys.contains($0) }
            
            // Transform to object ids ("marker.object_id" -> "object_id")
            let changedIds = changedKeys.map { CloudKeyValueStore.id(for: $0) }
            
            // Filter only changed objects
            markerParametersObjects = markerParametersObjects.filter({ (markerParameters) -> Bool in
                guard let id = markerParameters.id else { return false }
                return changedIds.contains(id)
            })
        }
        
        // Filter only objects that require an update
        markerParametersObjects = markerParametersObjects.filter { shouldUpdateLocalReferenceEntity(withMarkerParameters: $0) }
        
        importChanges(markerParametersObjects: markerParametersObjects, completion: completion)
    }
    
    /// Import marker parameters from cloud store to database
    private func importChanges(markerParametersObjects: [MarkerParameters], completion: (() -> Void)? = nil) {
        guard !markerParametersObjects.isEmpty else {
            completion?()
            return
        }
        
        let group = DispatchGroup()
        
        for markerParameters in markerParametersObjects {
            group.enter()
            importChanges(markerParameters: markerParameters) {
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            completion?()
        })
    }
    
    private func importChanges(markerParameters: MarkerParameters, completion: (() -> Void)? = nil) {
        // We load the underlying entity which either finds it in the local database,
        // or initializes and store a new underlying entity
        markerParameters.location.fetchEntity { [weak self] (result) in
            switch result {
            case .success(let entity):
                if let referenceEntity = ReferenceEntity(markerParameters: markerParameters, entity: entity) {
                    self?.importChanges(referenceEntity: referenceEntity)
                } else {
                    GDLogCloudInfo("Error initializing `ReferenceEntity` object for marker with id: \(markerParameters.id ?? "none")")
                }
            case .failure(let error):
                GDLogCloudInfo("Error loading underlying entity: \(error)")
            }
            
            completion?()
        }
    }
    
    /// Import reference entities from cloud store to database
    private func importChanges(referenceEntity: ReferenceEntity) {
        autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else { return }
            
            do {
                try database.write {
                    database.add(referenceEntity, update: .modified)
                }
                GDLogCloudInfo("Imported reference entity with id: \(referenceEntity.id), name: \(referenceEntity.name)")
            } catch {
                GDLogCloudInfo("Could not import reference entity with id: \(referenceEntity.id), name: \(referenceEntity.name), error: \(error)")
            }
        }
    }
    
    /// Store reference entities from database to cloud store
    private func store() {
        var localReferenceEntities = SpatialDataCache.referenceEntities()
        
        // Filter only objects that require an update
        localReferenceEntities = localReferenceEntities.filter { shouldUpdateCloudReferenceEntity(withLocalReferenceEntity: $0) }
        
        for referenceEntity in localReferenceEntities {
            store(referenceEntity: referenceEntity)
        }
    }
}

// MARK: Helpers

extension CloudKeyValueStore {
    
    private func shouldUpdateLocalReferenceEntity(withMarkerParameters markerParameters: MarkerParameters) -> Bool {
        // False if no id
        guard let id = markerParameters.id else { return false }
        
        // True if local database does not contain the cloud entity
        guard let localReferenceEntity = SpatialDataCache.referenceEntityByKey(id) else { return true }
        
        return localReferenceEntity.shouldUpdate(withMarkerParameters: markerParameters)
    }
    
    private func shouldUpdateCloudReferenceEntity(withLocalReferenceEntity localReferenceEntity: ReferenceEntity) -> Bool {
        // True if the cloud does not contain the local entity
        let key = CloudKeyValueStore.key(for: localReferenceEntity)
        guard let markerParameters = self.markerParameters(forKey: key) else { return true }
        
        return markerParameters.shouldUpdate(withReferenceEntity: localReferenceEntity)
    }
    
}

extension ReferenceEntity {
    
    fileprivate func shouldUpdate(withMarkerParameters markerParameters: MarkerParameters) -> Bool {
        // False if the other entity does not have a `lastUpdatedDate` property
        guard let otherLastUpdated = markerParameters.lastUpdatedDate else { return false }
        
        // True if this entity does not have a `lastUpdatedDate` property
        guard let selfLastUpdated = self.lastUpdatedDate else { return true }
        
        // True only if the last update date of the other entity is newer
        return otherLastUpdated > selfLastUpdated
    }
    
}

extension MarkerParameters {
    
    fileprivate func shouldUpdate(withReferenceEntity referenceEntity: ReferenceEntity) -> Bool {
        // False if the other entity does not have a `lastUpdatedDate` property
        guard let otherLastUpdated = referenceEntity.lastUpdatedDate else { return false }
        
        // True if this entity does not have a `lastUpdatedDate` property
        guard let selfLastUpdated = self.lastUpdatedDate else { return true }
        
        // True only if the last update date of the other entity is newer
        return otherLastUpdated > selfLastUpdated
    }
    
}
