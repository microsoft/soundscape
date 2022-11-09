//
//  GenericLocationSearchProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class GenericLocationSearchProvider: POISearchProviderProtocol {
    let providerName: String = "GenericLocationSearchProvider"
    
    func search(byKey key: String) -> POI? {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                GDLogSpatialDataError("Search by Key Error - Cannot get database Realm")
                return nil
            }
            
            // Search the cache
            return database.object(ofType: ReferenceEntity.self, forPrimaryKey: key)?.getPOI()
        }
    }
    
    func objects(predicate: NSPredicate) -> [POI] {
        return autoreleasepool {
            guard let database = try? RealmHelper.getDatabaseRealm() else {
                return []
            }
            
            // Reference entities that aren't temporary and don't have an underlying POI they refer to
            // represent generic locations (if there were an underlying POI, then they would be GDASpatialDataResultEntities).
            let entityPredicate = NSPredicate(format: "entityKey == nil AND isTemp == false")
            let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [entityPredicate, predicate])
            
            return database.objects(ReferenceEntity.self).filter(predicates).map { $0.getPOI() }
        }
    }
}
