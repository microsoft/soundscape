//
//  AddressSearchProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CocoaLumberjackSwift

class AddressSearchProvider: POISearchProviderProtocol {
    let providerName: String = "AddressPOISearchProvider"
    
    func search(byKey key: String) -> POI? {
        return autoreleasepool {
            guard let cache = try? RealmHelper.getCacheRealm() else {
                GDLogSpatialDataError("Search by Key Error - Cannot get cache Realm")
                return nil
            }
            
            // Search the cache
            return cache.object(ofType: Address.self, forPrimaryKey: key)
        }
    }
    
    func objects(predicate: NSPredicate) -> [POI] {
        return autoreleasepool {
            guard let cache = try? RealmHelper.getCacheRealm() else {
                DDLogError("Failed to get cache Realm")
                return []
            }
            
            return Array(cache.objects(Address.self).filter(predicate))
        }
    }
}
