//
//  LocationActionHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import MapKit

struct LocationActionHandler {
    
    // MARK: `typealias`
    
    typealias PreviewResult = Result<PreviewBehavior<IntersectionDecisionPoint>, LocationActionError>
    typealias PreviewCompletion = (PreviewResult) -> Void
    
    // MARK: `LocationAction` Methods
    
    static func save(locationDetail: LocationDetail) throws {
        let markerId: String?
        
        switch locationDetail.source {
        case .entity(let id):
            let nickname = locationDetail.nickname
            let estimatedAddress = locationDetail.estimatedAddress
            let annotation = locationDetail.annotation
            
            markerId = try? ReferenceEntity.add(entityKey: id, nickname: nickname, estimatedAddress: estimatedAddress, annotation: annotation, context: "location_action")
        case .coordinate:
            let latitude = locationDetail.location.coordinate.latitude
            let longitude = locationDetail.location.coordinate.longitude
            let nickname = locationDetail.nickname
            let estimatedAddress = locationDetail.estimatedAddress
            let annotation = locationDetail.annotation
            
            let genericLocation = GenericLocation(lat: latitude, lon: longitude)
            
            markerId = try? ReferenceEntity.add(location: genericLocation, nickname: nickname, estimatedAddress: estimatedAddress, annotation: annotation, temporary: false, context: "location_action")
            
        case .designData:
            markerId = nil
            
        case .screenshots:
            markerId = nil
        }
        
        guard let markerId = markerId, SpatialDataCache.referenceEntityByEntityKey(markerId) != nil else {
            throw LocationActionError.failedToSaveMarker
        }
        
        // Save selection
        locationDetail.updateLastSelectedDate()
    }
    
    static func beacon(locationDetail: LocationDetail) throws {
        do {
            switch locationDetail.source {
            case .entity(let id):
                // Set a beacon on the given entity
                try beacon(entityId: id)
                
            case .coordinate:
                let location = locationDetail.location
                let name = locationDetail.displayName
                let address = locationDetail.estimatedAddress
                
                // Set a beacon on the given coordinate
                try beacon(location: location, name: name, address: address)
                
            case .designData:
                break
                
            case .screenshots(let poi):
                try beacon(location: poi.location, name: poi.name, address: poi.addressLine)
            }
        } catch {
            throw LocationActionError.failedToSetBeacon
        }
        
        // Save selection
        locationDetail.updateLastSelectedDate()
    }
    
    static private func beacon(entityId: String) throws {
        let manager = AppContext.shared.spatialDataContext.destinationManager
        let userLocation = AppContext.shared.geolocationManager.location
        
        try manager.setDestination(entityKey: entityId, enableAudio: true, userLocation: userLocation, estimatedAddress: nil, logContext: "location_action")
    }
    
    static private func beacon(location: CLLocation, name: String, address: String?) throws {
        let manager = AppContext.shared.spatialDataContext.destinationManager
        let userLocation = AppContext.shared.geolocationManager.location
        
        let gLocation = GenericLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude, name: name)
        try manager.setDestination(location: gLocation, address: address, enableAudio: true, userLocation: userLocation, logContext: "location_action")
    }
    
    static func preview(locationDetail: LocationDetail, completion: @escaping PreviewCompletion) -> Progress? {
        // Save selection
        locationDetail.updateLastSelectedDate()
        
        return AppContext.shared.spatialDataContext.updateSpatialData(at: locationDetail.location) {
            guard let intersection = ReverseGeocoderContext.closestIntersection(for: locationDetail) else {
                GDATelemetry.track("preview.error.closest_intersection_not_found")
                completion(.failure(.failedToStartPreview))
                return
            }
            
            let decisionPoint = IntersectionDecisionPoint(node: intersection)
            
            guard decisionPoint.edges.count > 0 else {
                GDATelemetry.track("preview.error.edges_not_found")
                completion(.failure(.failedToStartPreview))
                return
            }
            
            let behavior = PreviewBehavior(at: decisionPoint,
                                           from: locationDetail,
                                           geolocationManager: AppContext.shared.geolocationManager,
                                           destinationManager: AppContext.shared.spatialDataContext.destinationManager)
            
            completion(.success(behavior))
        }
    }
    
    static func share(locationDetail: LocationDetail) throws -> URL {
        guard let url = UniversalLinkManager.shareLocation(locationDetail) else {
            throw LocationActionError.failedToShare
        }
        
        // Save selection
        locationDetail.updateLastSelectedDate()
        
        return url
    }
    
}
