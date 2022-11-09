//
//  TourWaypointDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

struct TourWaypointDetail {
    
    // MARK: Properties
    
    let index: Int
    let tourDetail: TourDetail
    
    var locationDetail: LocationDetail? {
        guard index >= 0, index < tourDetail.waypoints.count else {
            return nil
        }
        
        return tourDetail.waypoints[index]
    }
    
    var isActive: Bool {
        guard tourDetail.isGuidanceActive else {
            return false
        }
        
        // If guidance is active for this route, then the route will be
        // the active behavior
        guard let behavior = AppContext.shared.eventProcessor.activeBehavior as? GuidedTour else {
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
