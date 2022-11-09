//
//  BeaconDetailLabel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

struct BeaconDetailLocalizedLabel {
    
    // MARK: Properties
    
    let detail: BeaconDetail
    
    private var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute]
        formatter.maximumUnitCount = 0
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
    
    private var accessibilityFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .full
        return formatter
    }
    
    // MARK: `LocalizedLabel`
    
    var title: LocalizedLabel {
        var text: String
        var accessibilityText: String?
        
        if let routeDetail = detail.routeDetail {
            let name = routeDetail.displayName
            let count = String(routeDetail.waypoints.count)
            
            if let route = routeDetail.guidance, let index = route.currentWaypoint?.index {
                let indexStr = String(index + 1)
                
                text = GDLocalizedString("route.title", name, indexStr, count)
                accessibilityText = GDLocalizedString("route.title.accessibility_label", name, indexStr, count)
            } else {
                text = name
            }
        } else {
            text = GDLocalizedString("beacon.audio_beacon")
        }
        
        return LocalizedLabel(text: text, accessibilityText: accessibilityText)
    }
    
    var time: LocalizedLabel? {
        guard let routeDetail = detail.routeDetail else {
            return nil
        }
        
        return routeDetail.labels.time
    }
    
    var name: LocalizedLabel {
        let text = detail.locationDetail.displayName
        let accessibilityText = GDLocalizedString("beacon.beacon_on", text)
        
        return LocalizedLabel(text: text, accessibilityText: accessibilityText)
    }
    
    func distance(from userLocation: CLLocation?) -> LocalizedLabel {
        var text: String
        var accessibilityText: String?
        
        if let userLocation = userLocation, AppContext.shared.spatialDataContext.destinationManager.isUserWithinGeofence(userLocation) {
            text = GDLocalizedString("poi_screen.section_header.nearby")
        } else if let dLabel = detail.locationDetail.labels.distance(from: userLocation) {
            text = dLabel.text
            accessibilityText = dLabel.accessibilityText
        } else {
            text = GDLocalizedString("beacon.distance.unknown")
        }
        
        return LocalizedLabel(text: text, accessibilityText: accessibilityText)
    }
    
    func moreInformation(userLocation: CLLocation?) -> LocalizedLabel {
        var text: String
        var accessibilityText: String?
            
        if let userLocation = userLocation, AppContext.shared.spatialDataContext.destinationManager.isUserWithinGeofence(userLocation) {
            // "<Some Place> is nearby. Street address is <Some Address>"
            text = GDLocalizedString("directions.name_is_nearby_street_address", detail.locationDetail.displayName, detail.locationDetail.displayAddress)
        } else if let dLabel = detail.locationDetail.labels.distance(from: userLocation) {
            // "<Some Place> is currently <5 meters>. Street address is <Some Address>"
            text = GDLocalizedString("directions.name_is_currently_street_address", detail.locationDetail.displayName, dLabel.text, detail.locationDetail.displayAddress)
            accessibilityText = GDLocalizedString("directions.name_is_currently_street_address", detail.locationDetail.displayName, dLabel.accessibilityText ?? dLabel.text, detail.locationDetail.displayAddress)
        } else {
            // "<Some Place>. Street address is <Some Address>. Distance unknown."
            text = GDLocalizedString("directions.name_street_address", detail.locationDetail.displayName, detail.locationDetail.displayAddress)
        }
            
        return LocalizedLabel(text: text, accessibilityText: accessibilityText)
    }
    
}

extension BeaconDetail {
    
    var labels: BeaconDetailLocalizedLabel {
        return BeaconDetailLocalizedLabel(detail: self)
    }
    
}
