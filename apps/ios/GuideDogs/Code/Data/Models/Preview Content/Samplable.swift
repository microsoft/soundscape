//
//  Samplable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import RealmSwift
import CoreLocation

protocol Samplable {
    associatedtype Item
    static var sample: Item { get }
    static var samples: [Item] { get }
}

extension CLLocation: Samplable {
    static var samples: [CLLocation] { [sample] }
    
    static var sample: CLLocation {
        // Near 9th Ave N and Harrison in SLU Seattle
        CLLocation(latitude: 47.622491, longitude: -122.339840)
    }
}

extension ReferenceEntity: Samplable {
    static var samples: [ReferenceEntity] { [sample, sample2, sample3, sample4] }
    
    static var sample: ReferenceEntity {
        ReferenceEntity(location: .init(lat: 47.622918, lon: -122.338521, name: "Republic"),
                        name: "Republic",
                        estimatedAddress: "429 Westlake Ave N, Seattle, WA 98109",
                        annotation: "This is my favorite restaurant",
                        temp: false)
    }
    
    static var sample2: ReferenceEntity {
        ReferenceEntity(location: .init(lat: 47.618433, lon: -122.338346, name: "Whole Foods"),
                        name: "Grocery Store",
                        estimatedAddress: nil,
                        annotation: nil,
                        temp: false)
    }
    
    static var sample3: ReferenceEntity {
        let entity = ReferenceEntity(location: .init(lat: 47.620226, lon: -122.349204),
                                     name: "Space Needle",
                                     estimatedAddress: "400 Broad St, Seattle, WA 98109",
                                     annotation: nil,
                                     temp: false)
        entity.isNew = false
        return entity
    }
    
    static var sample4: ReferenceEntity {
        let entity = ReferenceEntity(location: .init(lat: 47.627578, lon: -122.337055),
                                     name: "Museum of History & Industry",
                                     estimatedAddress: nil,
                                     annotation: nil,
                                     temp: false)
        entity.isNew = false
        return entity
    }
}

extension RouteWaypoint: Samplable {
    static var samples: [RouteWaypoint] { [sample, sample2, sample3, sample4] }
    
    static var sample: RouteWaypoint {
        RouteWaypoint(index: 0, markerId: ReferenceEntity.sample.id)!
    }
    
    static var sample2: RouteWaypoint {
        RouteWaypoint(index: 1, markerId: ReferenceEntity.sample2.id)!
    }
    
    static var sample3: RouteWaypoint {
        RouteWaypoint(index: 2, markerId: ReferenceEntity.sample3.id)!
    }
    
    static var sample4: RouteWaypoint {
        RouteWaypoint(index: 3, markerId: ReferenceEntity.sample4.id)!
    }
}

extension Route: Samplable {
    static var samples: [Route] { [sample] }
    
    static var sample: Route {
        Route(name: "Seattle Sightseeing Tour", description: "This is a little walk through Seattle's South Lake Union neighborhood", waypoints: RouteWaypoint.samples)
    }
}

extension Realm: Samplable {
    static var samples: [Realm] { [sample] }
    static var sample: Realm {
        do {
            let realm = try Realm(configuration: RealmHelper.databaseConfig)
            try realm.write {
                realm.deleteAll()
                ReferenceEntity.samples.forEach { entity in
                    realm.add(entity)
                }
                
                Route.samples.forEach { route in
                    realm.add(route)
                }
            }
            return realm
        } catch {
            fatalError("Failed to create a test Realm")
        }
    }
    
    static func bootstrap() {
        do {
            if let fileURL = RealmHelper.databaseConfig.fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                // Delete cached Realm file
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let realm = try Realm(configuration: RealmHelper.databaseConfig)
            try realm.write {
                realm.deleteAll()
                realm.add(ReferenceEntity.samples)
                realm.add(Route.samples)
            }
        } catch {
            print("Failed to bootstrap the default realm")
        }
    }
}
