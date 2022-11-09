//
//  WaypointDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol RouteDetailProtocol {
    var id: String { get }
    var waypoints: [LocationDetail] { get }
    var isGuidanceActive: Bool { get }
}

struct WaypointDetail {
    
    // MARK: Properties
    
    let index: Int
    let routeDetail: RouteDetailProtocol
    
    var locationDetail: LocationDetail? {
        guard index >= 0, index < routeDetail.waypoints.count else {
            return nil
        }
        
        return routeDetail.waypoints[index]
    }
    
    var isActive: Bool {
        guard routeDetail.isGuidanceActive else {
            return false
        }
        
        // If guidance is active for this route, then the route will be
        // the active behavior
        guard let behavior = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            return false
        }
        
        guard let activeIndex = behavior.state.waypointIndex else {
            return false
        }
        
        return index == activeIndex
    }
    
    var displayName: String {
        if let displayName = locationDetail?.displayName, displayName.isEmpty == false {
            return displayName
        }
        
        return GDLocalizedString("location")
    }
    
    var displayIndex: String {
        return String(index + 1)
    }
}
