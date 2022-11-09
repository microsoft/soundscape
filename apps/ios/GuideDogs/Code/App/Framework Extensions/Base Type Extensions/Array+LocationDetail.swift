//
//  Array+LocationDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Array where Element == LocationDetail {
    
    var asIdenfifiable: [IdentifiableLocationDetail] {
        return compactMap({ return IdentifiableLocationDetail(locationDetail: $0) })
    }
    
    var asRouteWaypoint: [RouteWaypoint] {
        return enumerated()
            .compactMap({ return RouteWaypoint(index: $0.offset, locationDetail: $0.element) })
    }
    
}

extension Array where Element == IdentifiableLocationDetail {
    
    var asLocationDetail: [LocationDetail] {
        return compactMap({ return $0.locationDetail })
    }
    
    var asRouteWaypoint: [RouteWaypoint] {
        return asLocationDetail
            .asRouteWaypoint
    }
    
}
