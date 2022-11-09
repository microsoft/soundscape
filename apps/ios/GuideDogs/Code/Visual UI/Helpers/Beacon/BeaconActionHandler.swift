//
//  BeaconActionHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import SwiftUI

struct BeaconActionHandler {
    
    ///
    /// `createMarker(detail: BeaconDetail)`
    ///
    /// parameter detail is the `BeaconDetail` object corresponding to the expected `ReferenceEntity`
    ///
    /// returns `UIViewController` if a view controller is returned, then the calling view or view controller should present the view controller
    ///
    static func createMarker(detail: BeaconDetail) -> UIViewController? {
        guard let key = detail.locationDetail.beaconId else {
            return nil
        }
        
        guard let beacon = SpatialDataCache.referenceEntityByKey(key) else {
            // Failed to fetch beacon
            return nil
        }
        
        guard beacon.isTemp else {
            return nil
        }
        
        let config = EditMarkerConfig(detail: LocationDetail(marker: beacon),
                                      route: nil,
                                      context: "beacon_view",
                                      addOrUpdateAction: .popViewController,
                                      deleteAction: nil,
                                      leftBarButtonItemIsHidden: false)
        
        return MarkerEditViewRepresentable(config: config).makeViewController()
    }
    
    ///
    /// `callout(detail: BeaconDetail)`
    ///
    /// parameter detail is the `BeaconDetail` object corresponding to the expected `ReferenceEntity`
    ///
    /// queues a call out for the given audio beacon
    ///
    static func callout(detail: BeaconDetail) {
        callout(detail: detail.locationDetail)
    }
    
    ///
    /// `callout(detail: LocationDetail)`
    ///
    /// parameter detail is the `LocationDetail` object corresponding to the expected `ReferenceEntity`
    ///
    /// queues a call out for the given audio beacon
    ///
    static func callout(detail: LocationDetail) {
        guard let key = detail.beaconId else {
            return
        }
        
        AppContext.process(BeaconCalloutEvent(beaconId: key, logContext: "home_screen"))
        GDATelemetry.track("beacon.callout")
    }
    
    ///
    /// `toggleAudio`
    ///
    /// toggles the audio for the current audio beacon
    ///
    static func toggleAudio() {
        guard AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio(automatic: false) else {
            // Failed to toggle audio
            return
        }
        
        let isAudioEnabled = AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled
        GDATelemetry.track("beacon.toggle_audio", value: String(isAudioEnabled))
    }
    
    ///
    /// `moreInformation(detail: BeaconDetail, userLocation: CLLocation)`
    ///
    /// parameters
    /// - detail is the `BeaconDetail` object corresponding to the expected `ReferenceEntity`
    /// - userLocation is the user's current location
    ///
    /// queues a call out for the given audio beacon
    ///
    static func moreInformation(detail: BeaconDetail, userLocation: CLLocation?) {
        let dLabel = detail.labels.moreInformation(userLocation: userLocation)
        let moreInformation = dLabel.accessibilityText ?? dLabel.text
        
        // Post accessibility annoucement
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: moreInformation)
        
        GDATelemetry.track("beacon.more_info")
    }
    
    ///
    /// `remove`
    ///
    /// removes the current audio beacon
    ///
    static func remove(detail: BeaconDetail) {
        if let routeDetail = detail.routeDetail {
            guard routeDetail.isGuidanceActive else {
                return
            }
            
            AppContext.shared.eventProcessor.deactivateCustom()
        } else {
            guard AppContext.shared.spatialDataContext.destinationManager.destinationKey == detail.locationDetail.beaconId else {
                // There is no beacon to clear
                return
            }
            
            do {
                // Try to remove the beacon
                try AppContext.shared.spatialDataContext.destinationManager.clearDestination(logContext: "home_screen")
            } catch {
                return
            }
            
            GDLogActionInfo("Clear destination")
        }
    }
    
}
