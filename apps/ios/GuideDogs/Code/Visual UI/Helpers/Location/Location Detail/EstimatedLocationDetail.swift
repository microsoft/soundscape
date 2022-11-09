//
//  EstimatedLocationDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct EstimatedLocationDetail {
    
    // MARK: Properties
    
    let name: String
    let address: String?
    
    // MARK: Initialization
    
    private init(name: String, address: String?) {
        self.name = name
        self.address = address
    }
    
    static func make(for value: LocationDetail, completion: @escaping (EstimatedLocationDetail) -> Void) {
        // Search for an OSM polygon containing the given location
        // using entities that are closest to the given location
        let dataView = AppContext.shared.spatialDataContext.getDataView(for: value.location)
        let nearbyEntities = dataView?.pois.sorted(by: Sort.distance(origin: value.location), maxLength: 20)
        
        let atEntity = nearbyEntities?.first(where: { $0.contains(location: value.location.coordinate) })
        
        SpatialDataCache.fetchEstimatedAddress(location: value.location) { (address) in
            let estimatedName: String
            let estimatedAddress: String?
            
            if let atEntity = atEntity {
                // If the location is contained within an OSM polygon
                // use the name of the polygon
                estimatedName = atEntity.localizedName
            } else if let streetName = address?.streetName, streetName.isEmpty == false {
                // Save estimated value
                estimatedName = GDLocalizedString("directions.near_name", streetName)
            } else if let result = AppContext.shared.reverseGeocoder.reverseGeocode(value.location) {
                // Apple's geocoder didn't get us a result, so we are falling back to our geocoder
                switch result {
                case is GenericGeocoderResult:
                    // The user isn't within a POI or adjacent to a road, use the default name
                    estimatedName = GDLocalizedString("location")
                    
                case let inside as InsideGeocoderResult:
                    estimatedName = inside.poi?.localizedName ?? GDLocalizedString("location")
                    
                case let alongside as AlongsideGeocoderResult:
                    // Save estimated value
                    if let roadName = alongside.closestRoad?.name {
                        estimatedName = GDLocalizedString("directions.near_name", roadName)
                    } else {
                        // When a name is not provided, use the default name
                        estimatedName = GDLocalizedString("location")
                    }
                    
                default:
                    // When a name is not provided, use the default name
                    estimatedName = GDLocalizedString("location")
                }
            } else {
                // When a name is not provided, use the default name
                estimatedName = GDLocalizedString("location")
            }
            
            if let addressLine = address?.addressLine, addressLine.isEmpty == false {
                // Save estimated value
                estimatedAddress = addressLine
            } else {
                estimatedAddress = nil
            }
            
            let value = EstimatedLocationDetail(name: estimatedName, address: estimatedAddress)
            completion(value)
        }
    }
    
}
