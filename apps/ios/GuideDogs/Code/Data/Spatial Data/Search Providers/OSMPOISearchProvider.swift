//
//  OSMPOISearchProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

class OSMPOISearchProvider: POISearchProviderProtocol {
    let providerName: String = "OSMPOISearchProvider"
    
    func search(byKey key: String) -> POI? {
        return autoreleasepool {
            guard let cache = try? RealmHelper.getCacheRealm() else {
                GDLogSpatialDataError("Search by Key Error - Cannot get cache Realm")
                return nil
            }
            
            // Search the cache
            return cache.object(ofType: GDASpatialDataResultEntity.self, forPrimaryKey: key)
        }
    }
    
    func objects(predicate: NSPredicate) -> [POI] {
        return autoreleasepool {
            guard let cache = try? RealmHelper.getCacheRealm() else {
                return []
            }
            
            return Array(cache.objects(GDASpatialDataResultEntity.self).filter(predicate))
        }
    }
}
