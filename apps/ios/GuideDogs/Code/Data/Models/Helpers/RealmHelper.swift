//
//  RealmHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import RealmSwift

class RealmHelper {
    
    // MARK: Properties
    
    fileprivate static let shared = RealmHelper()
    private(set) var cacheConfig: Realm.Configuration
    let databaseConfig: Realm.Configuration
    
    // MARK: Initialization
    
    private init() {
        // Initialize `cacheConfig`
        let (config, _) = RealmHelper.currentCacheConfig
        self.cacheConfig = config
        
        //
        // Initialize `databaseConfig`
        //
        var databaseConfig = Realm.Configuration.defaultConfiguration
        
        databaseConfig.fileURL = databaseConfig.fileURL?.deletingLastPathComponent().appendingPathComponent("database").appendingPathExtension("realm")
        databaseConfig.schemaVersion = 0
        databaseConfig.objectTypes = [ReferenceEntity.self, Route.self, RouteWaypoint.self]
        
        self.databaseConfig = databaseConfig
    }
    
    // MARK: Realm Methods
    
    func incrementCacheConfig() {
        var (cacheConfig, currentID) = RealmHelper.currentCacheConfig
        
        let id: Int
        
        if let currentID = currentID {
            // Increment the ID used to name the new cache config file
            id = currentID + 1
        } else {
            // Existing cache config file does not include an ID
            // Initialize the ID to be 1
            id = 1
        }
        
        cacheConfig.fileURL = cacheConfig.fileURL?.deletingLastPathComponent().appendingPathComponent("cache.\(id)").appendingPathExtension("realm")
        
        self.cacheConfig = cacheConfig
    }
    
}

extension RealmHelper {
    
    // MARK: Static Realm Methods
    
    private static var currentCacheConfig: (config: Realm.Configuration, id: Int?) {
        // Get the default configuration for the cache
        var cacheConfig = Realm.Configuration.defaultConfiguration
        
        // Initialize schema version and expected object
        // classes
        cacheConfig.schemaVersion = 0
        cacheConfig.objectTypes = [Intersection.self, IntersectionRoadId.self, TileData.self, GDASpatialDataResultEntity.self, LocalizedString.self, Address.self, RealmString.self]
        
        guard let directoryURL = cacheConfig.fileURL?.deletingLastPathComponent() else {
            return (config: cacheConfig, id: nil)
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            
            var maxID = -1
            var urlWithMaxID: URL?
            
            for url in fileURLs {
                let split = url.lastPathComponent.split(separator: ".")
                
                guard split.last == "realm" else {
                    continue
                }
                
                guard split.first == "cache" else {
                    continue
                }
                
                guard let id = Int(split[1]) else {
                    continue
                }
                
                if id > maxID {
                    maxID = id
                    urlWithMaxID = url
                }
            }
            
            guard let url = urlWithMaxID, maxID > -1 else {
                // Failed to find
                return (config: cacheConfig, id: nil)
            }
            
            cacheConfig.fileURL = url
            
            return (config: cacheConfig, id: maxID)
            
        } catch {
            return (config: cacheConfig, id: nil)
        }
    }
    
    static func incrementCacheConfig() {
        RealmHelper.shared.incrementCacheConfig()
    }
    
    static var cacheConfig: Realm.Configuration {
        return RealmHelper.shared.cacheConfig
    }
    
    static var databaseConfig: Realm.Configuration {
        return RealmHelper.shared.databaseConfig
    }
    
    class func getDatabaseRealm() throws -> Realm {
        return try Realm(configuration: databaseConfig)
    }
    
    class func getDatabaseRealm(config: Realm.Configuration = databaseConfig) throws -> Realm {
        return try Realm(configuration: config)
    }
    
    class func getCacheRealm() throws -> Realm {
        return try Realm(configuration: cacheConfig)
    }
    
    class func getCacheRealm(config: Realm.Configuration = cacheConfig) throws -> Realm {
        return try Realm(configuration: config)
    }
    
}
