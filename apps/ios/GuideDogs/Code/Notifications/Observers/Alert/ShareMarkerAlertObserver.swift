//
//  ShareMarkerAlertObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class ShareMarkerAlertObserver: NotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    var didDismiss: Bool = false
    private var currentAlert: UIAlertController?
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onImportMarker), name: Notification.Name.didImportMarker, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onImportContentDidFail), name: Notification.Name.didFailToImportMarker, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onImportMarker(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            presentErrorAlert()
            return
        }
        
        guard let location = userInfo[ShareMarkerLinkHandler.Keys.location] as? POI else {
            presentErrorAlert()
            return
        }
        
        // Optional parameters
        let nickname = userInfo[ShareMarkerLinkHandler.Keys.nickname] as? String
        let annotation = userInfo[ShareMarkerLinkHandler.Keys.annotation] as? String
        
        presentImportMarkerAlert(location: location, nickname: nickname, annotation: annotation)
    }
    
    @objc
    private func onImportContentDidFail() {
        presentErrorAlert()
    }
    
    // MARK: Alert Segues
    
    private func segueToEditImportedMarker(location: POI, nickname: String?, annotation: String?) {
        let destination = MarkerEditViewRepresentable(entity: location, nickname: nickname, annotation: annotation, telemetryContext: "universal_link.new")
        
        // Segue to edit marker view
        self.delegate?.performSegue(self, destination: destination)
    }
    
    private func segueToEditExistingMarker(marker: ReferenceEntity, nickname: String?, annotation: String?) {
        let destination = MarkerEditViewRepresentable(marker: marker, nickname: nickname, annotation: annotation, telemetryContext: "universal_link.existing")
        
        // Segue to edit marker view
        self.delegate?.performSegue(self, destination: destination)
    }
    
    // MARK: Alerts
    
    private func defaultAlertActionHandler(_ action: UIAlertAction) {
        GDATelemetry.track("deeplink.share_marker.alert_cancel")
        
        // Reset `currentAlert` after it has been presented
        self.currentAlert = nil
    }
    
    private func presentImportMarkerAlert(location: POI, nickname: String?, annotation: String?) {
        GDATelemetry.track("deeplink.share_marker.alert_import")
        
        // Save the imported location as a marker
        let markerHandler: (UIAlertAction) -> Void = { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            GDATelemetry.track("deeplink.share_marker.save_marker")
            
            // Reset `currentAlert` after it has been presented
            self.currentAlert = nil
            
            // Search for an existing reference entity at the given
            // location
            let existingMarker: ReferenceEntity?
            
            if let location = location as? GenericLocation {
                existingMarker = SpatialDataCache.referenceEntityByGenericLocation(location)
            } else {
                existingMarker = SpatialDataCache.referenceEntityByEntityKey(location.key)
            }
            
            if let existingMarker = existingMarker {
                // A marker already exists at the given location
                // Present another alert to ask the user what to do
                self.presentImportExistingMarkerAlert(existingMarker: existingMarker, nickname: nickname, annotation: annotation)
            } else {
                self.segueToEditImportedMarker(location: location, nickname: nickname, annotation: annotation)
            }
        }
        
        // Set a beacon on the imported location
        let beaconHandler: (UIAlertAction) -> Void = { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            GDATelemetry.track("deeplink.share_marker.set_beacon")
            
            // Reset `currentAlert` after it has been presented
            self.currentAlert = nil
            
            let manager = AppContext.shared.spatialDataContext.destinationManager
            let userLocation = AppContext.shared.geolocationManager.location
            
            do {
                if let location = location as? GenericLocation {
                    try manager.setDestination(location: location, address: nil, enableAudio: true, userLocation: userLocation, logContext: "universal_link")
                } else {
                    try manager.setDestination(entityKey: location.key, enableAudio: true, userLocation: userLocation, estimatedAddress: nil, logContext: "universal_link")
                }
                
                self.delegate?.popToRootViewController(self)
            } catch {
                self.presentErrorAlert()
            }
        }
        
        let name = nickname ?? location.name
        
        // Save alert
        self.currentAlert = ShareMarkerAlert.importMarker(name: name, markerHandler: markerHandler, beaconHandler: beaconHandler, cancelHandler: defaultAlertActionHandler)
        
        delegate?.stateDidChange(self)
    }
    
    private func presentImportExistingMarkerAlert(existingMarker: ReferenceEntity, nickname: String?, annotation: String?) {
        GDATelemetry.track("deeplink.share_marker.alert_existing")
        
        let replaceHandler: (UIAlertAction) -> Void = { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            GDATelemetry.track("deeplink.share_marker.replace")
            
            // Reset `currentAlert` after it has been presented
            self.currentAlert = nil
            
            self.segueToEditExistingMarker(marker: existingMarker, nickname: nickname, annotation: annotation)
        }
        
        // Save alert
        self.currentAlert = ShareMarkerAlert.importExistingMarker(replaceHandler: replaceHandler, cancelHandler: defaultAlertActionHandler)

        delegate?.stateDidChange(self)
    }
    
    private func presentErrorAlert() {
        GDATelemetry.track("deeplink.share_marker.alert_error")
        
        // Save alert
        self.currentAlert = ShareMarkerAlert.importError(dismissHandler: defaultAlertActionHandler)
        
        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationObserver`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        return currentAlert
    }
    
}
