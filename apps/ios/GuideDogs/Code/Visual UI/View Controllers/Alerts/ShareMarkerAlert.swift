//
//  ShareContentAlert.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct ShareMarkerAlert: ShareAlertFactory {
    
    // MARK: Error Alerts
    
    static func importError(dismissHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("universal_links.alert.error.title")
        let message = GDLocalizedString("universal_links.alert.import_error.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add action to dismiss
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler))
        
        return alert
    }
    
    // MARK: Import Alerts
    
    static func importMarker(name: String, markerHandler: ActionHandler? = nil, beaconHandler: ActionHandler? = nil, cancelHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("universal_links.marker.alert.title", name)
        let message = GDLocalizedString("universal_links.marker.alert.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        // Add action to save as marker
        alert.addAction(UIAlertAction(title: GDLocalizedString("universal_links.alert.action.marker"), style: .default, handler: markerHandler))
        
        // Beacon action is disabled while route guidance is active
        if (AppContext.shared.eventProcessor.activeBehavior is RouteGuidance) == false {
            // Add action to set a beacon
            alert.addAction(UIAlertAction(title: GDLocalizedString("universal_links.alert.action.beacon"), style: .default, handler: beaconHandler))
        }
        
        // Add cancel action
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: cancelHandler))
        
        return alert
    }
    
    static func importExistingMarker(replaceHandler: ActionHandler? = nil, cancelHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("universal_links.marker_existing.alert.title")
        let message = GDLocalizedString("universal_links.marker_existing.alert.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add action to replace the existing marker
        let yesAction = UIAlertAction(title: GDLocalizedString("general.alert.yes"), style: .default, handler: replaceHandler)
        alert.addAction(yesAction)
        alert.preferredAction = yesAction
        
        // Add cancel action
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: cancelHandler))
        
        return alert
    }
    
    // MARK: Share Activity View Controllers
    
    static func shareMarker(_ url: URL, markerName: String) -> UIActivityViewController {
        let message = GDLocalizedString("universal_links.marker.share.message", markerName)
        let items: [Any] = [message, url]
        
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    static func shareMarker(_ marker: ReferenceEntity) -> UIActivityViewController? {
        guard let url = UniversalLinkManager.shareMarker(marker) else {
            return nil
        }
        
        return shareMarker(url, markerName: marker.name)
    }
    
    static func shareMarker(name: String, latitude: Double, longitude: Double) -> UIActivityViewController? {
        guard let url = UniversalLinkManager.shareLocation(name: name, latitude: latitude, longitude: longitude) else {
            return nil
        }
        
        return shareMarker(url, markerName: name)
    }
    
}
