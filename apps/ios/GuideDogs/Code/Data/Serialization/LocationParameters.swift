//
//  LocationParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct LocationParameters: Codable {
    
    // MARK: Properties
    
    let name: String
    let address: String?
    // `UniversalLinkParameter` Properties
    let coordinate: CoordinateParameters
    let entity: EntityParameters?
    
}

extension LocationParameters {
    
    typealias Completion = (Result<POI, Error>) -> Void
    
    func fetchEntity(completion: @escaping Completion) {
        if let entity = entity {
            addOrUpdate(entity: entity, completion: completion)
        } else {
            let name = self.name
            let latitude = coordinate.latitude
            let longitude = coordinate.longitude
            
            let genericLocation = GenericLocation(lat: latitude, lon: longitude, name: name)
            
            completion(.success(genericLocation))
        }
    }
    
    private func addOrUpdate(entity: EntityParameters, completion: @escaping Completion) {
        switch entity.source {
        case .osm: addOrUpdateOSMEntity(id: entity.lookupInformation, completion: completion)
        }
    }
    
    private func addOrUpdateOSMEntity(id: String, completion: @escaping Completion) {
        DispatchQueue.main.async {
            if let entity = SpatialDataCache.searchByKey(key: id) as? GDASpatialDataResultEntity {
                // Data for the OSM entity has already been cached on the device
                completion(.success(entity))
            } else {
                // Create a new OSM entity and cache on the device
                let entity = GDASpatialDataResultEntity(id: id, parameters: self)
                
                do {
                    try autoreleasepool {
                        let cache = try RealmHelper.getCacheRealm()
                        
                        try cache.write {
                            cache.add(entity, update: .modified)
                        }
                        
                        completion(.success(entity))
                    }
                } catch {
                    // Failed to save the entity
                    completion(.failure(error))
                }
            }
        }
    }
    
}
extension LocationParameters: UniversalLinkParameters {
    
    private struct Name {
        static let name = "name"
    }
    
    // MARK: Properties
    
    var queryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        
        // Append name
        queryItems.append(URLQueryItem(name: Name.name, value: name))
        
        // Append coordinate query items
        queryItems.append(contentsOf: coordinate.queryItems)
        
        if let entity = entity {
            // Append entity query items
            queryItems.append(contentsOf: entity.queryItems)
        }
        
        return queryItems
    }
    
    // MARK: Initialization
    
    init?(queryItems: [URLQueryItem]) {
        guard let coordinate = CoordinateParameters(queryItems: queryItems) else {
            return nil
        }
        
        guard let name = queryItems.first(where: { $0.name == Name.name })?.value else {
            return nil
        }
        
        self.name = name
        // `address` is not used in universal links
        self.address = nil
        self.coordinate = coordinate
        self.entity = EntityParameters(queryItems: queryItems)
    }
    
}
