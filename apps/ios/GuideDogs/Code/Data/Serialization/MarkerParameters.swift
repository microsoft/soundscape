//
//  MarkerParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum ImportMarkerError: Error {
    case invalidParameter
    case entityNotFound
    case unableToImportLocalEntity
    case failedToFetchMarker
}

struct MarkerParameters: Codable {
    
    // MARK: Properties
    
    /// Refers to the `ReferenceEntity` id, if applicable
    let id: String?
    let nickname: String?
    let annotation: String?
    let estimatedAddress: String?
    let lastUpdatedDate: Date?

    // `UniversalLinkParameter` Properties
    let location: LocationParameters
    
    // MARK: Initialization
    
    private init?(entity: POI, markerId: String?, estimatedAddress: String?, nickname: String?, annotation: String?, lastUpdatedDate: Date?) {
        let location: LocationParameters
        
        if let entity = entity as? GDASpatialDataResultEntity {
            let id = entity.key
            let name = entity.localizedName
            let address = entity.addressLine
            let coordinate = CoordinateParameters(latitude: entity.centroidLatitude, longitude: entity.centroidLongitude)
            
            // Initialize parameters for an OSM entity
            let entityParameters = EntityParameters(source: .osm, lookupInformation: id)
            
            // Initialize location parameters
            location = LocationParameters(name: name, address: address, coordinate: coordinate, entity: entityParameters)
        } else {
            let coordinate = CoordinateParameters(latitude: entity.centroidLatitude, longitude: entity.centroidLongitude)
            
            // Initialize location parameters
            location = LocationParameters(name: entity.localizedName, address: nil, coordinate: coordinate, entity: nil)
        }
        
        if let markerId = markerId, markerId.isEmpty == false {
            self.id = markerId
        } else {
            self.id = nil
        }
        
        if let nickname = nickname, nickname.isEmpty == false {
            self.nickname = nickname
        } else {
            self.nickname = nil
        }
        
        if let annotation = annotation, annotation.isEmpty == false {
            self.annotation = annotation
        } else {
            self.annotation = nil
        }
        
        if let estimatedAddress = estimatedAddress, estimatedAddress.isEmpty == false {
            self.estimatedAddress = estimatedAddress
        } else {
            self.estimatedAddress = nil
        }
        
        self.lastUpdatedDate = lastUpdatedDate
        self.location = location
    }
    
    init?(marker: ReferenceEntity) {
        let entity = marker.getPOI()
        let markerId = marker.id
        let estimatedAddress = marker.estimatedAddress
        let nickname = marker.nickname
        let annotation = marker.annotation
        let lastUpdatedDate = marker.lastUpdatedDate
        
        self.init(entity: entity, markerId: markerId, estimatedAddress: estimatedAddress, nickname: nickname, annotation: annotation, lastUpdatedDate: lastUpdatedDate)
    }
    
    init?(markerId: String) {
        guard let marker = SpatialDataCache.referenceEntityByKey(markerId) else {
            return nil
        }
        
        self.init(marker: marker)
    }
    
    init?(entity: POI) {
        if let entity = entity as? GenericLocation, let marker = SpatialDataCache.referenceEntityByLocation(entity.location.coordinate) {
            self.init(marker: marker)
        } else if let marker = SpatialDataCache.referenceEntityByEntityKey(entity.key) {
            self.init(marker: marker)
        } else {
            self.init(entity: entity, markerId: nil, estimatedAddress: nil, nickname: nil, annotation: nil, lastUpdatedDate: nil)
        }
    }
    
    init?(location detail: LocationDetail) {
        let entity: POI
        
        switch detail.source {
        case .entity(let id):
            guard let cachedEntity = SpatialDataCache.searchByKey(key: id) else {
                return nil
            }
            
            entity = cachedEntity
        case .coordinate:
            let latitude = detail.location.coordinate.latitude
            let longitude = detail.location.coordinate.longitude
            
            // Initialize a `GenericLocation` entity
            entity = GenericLocation(lat: latitude, lon: longitude)
            
        case .designData(let location, _):
            entity = GenericLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            
        case .screenshots(let poi):
            entity = poi
        }
        
        let markerId = detail.markerId
        let estimatedAddress = detail.estimatedAddress
        let nickname = detail.nickname
        let annotation = detail.annotation
        
        let lastUpdatedDate: Date?
        
        if let markerId = markerId, let marker = SpatialDataCache.referenceEntityByEntityKey(markerId) {
            lastUpdatedDate = marker.lastUpdatedDate
        } else {
            lastUpdatedDate = nil
        }
        
        self.init(entity: entity, markerId: markerId, estimatedAddress: estimatedAddress, nickname: nickname, annotation: annotation, lastUpdatedDate: lastUpdatedDate)
    }
    
    init(name: String, latitude: Double, longitude: Double) {
        let coordinate = CoordinateParameters(latitude: latitude, longitude: longitude)
        let location = LocationParameters(name: name, address: nil, coordinate: coordinate, entity: nil)
        
        self.id = nil
        self.nickname = nil
        self.annotation = nil
        self.estimatedAddress = nil
        self.lastUpdatedDate = nil
        self.location = location
    }
    
}

extension MarkerParameters: UniversalLinkParameters {
    
    private struct Name {
        static let nickname = "nickname"
        static let annotation = "annotation"
    }
    
    // MARK: Properties
    
    var queryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
    
        if let nickname = nickname {
            // Append nickname
            queryItems.append(URLQueryItem(name: Name.nickname, value: nickname))
        }
        
        if let annotation = annotation {
            // Append annotation
            queryItems.append(URLQueryItem(name: Name.annotation, value: annotation))
        }
        
        // Append location query items
        queryItems.append(contentsOf: location.queryItems)
        
        return queryItems
    }
    
    // MARK: Initialization
    
    init?(queryItems: [URLQueryItem]) {
        guard let location = LocationParameters(queryItems: queryItems) else {
            return nil
        }
        
        self.id = nil
        self.nickname = queryItems.first(where: { $0.name == Name.nickname })?.value
        self.annotation = queryItems.first(where: { $0.name == Name.annotation })?.value
        // `estimatedAddress` is not used in universal links
        self.estimatedAddress = nil
        self.lastUpdatedDate = nil
        self.location = location
    }
    
}

extension MarkerParameters {
    
    typealias Completion = (Result<LocationDetail, Error>) -> Void
    
    func fetchMarker(completion: @escaping Completion) {
        // Fetch the underlying entity
        //
        // For OSM entities, add or update the entity in the cache
        location.fetchEntity { (result) in
            switch result {
            case .success(let entity):
                let importedDetail = ImportedLocationDetail(nickname: nickname, annotation: annotation)
                let locationDetail = LocationDetail(entity: entity, imported: importedDetail, telemetryContext: nil)
                completion(.success(locationDetail))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
