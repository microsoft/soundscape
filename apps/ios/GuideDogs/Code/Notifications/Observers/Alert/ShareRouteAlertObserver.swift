//
//  ShareRouteAlertObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class ShareRouteAlertObserver: NotificationObserver {
    
    // MARK: Properties
    
    weak var delegate: NotificationObserverDelegate?
    var didDismiss: Bool = false
    private var currentAlert: UIAlertController?
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onImportRoute), name: Notification.Name.didImportRoute, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onImportRouteDidFail), name: Notification.Name.didFailToImportRoute, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    private func onImportRoute(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            presentErrorAlert()
            return
        }
        
        guard let route = userInfo[RouteResourceHandler.Keys.route] as? Route else {
            presentErrorAlert()
            return
        }
        
        presentImportRouteAlert(route: route)
    }
    
    @objc
    private func onImportRouteDidFail() {
        presentErrorAlert()
    }
    
    // MARK: Alert Segues
    
    private func segueToEditRoute(route: Route) {
        let destination = RouteEditViewRepresentable(style: .import(route: route))
        
        // Segue to edit marker view
        self.delegate?.performSegue(self, destination: destination)
    }
    
    // MARK: Alerts
    
    private func defaultAlertActionHandler(_ action: UIAlertAction) {
        GDATelemetry.track("url_resource.import_route.alert_cancel")
        
        // Reset `currentAlert` after it has been presented
        self.currentAlert = nil
    }
    
    private func presentImportRouteAlert(route: Route) {
        GDATelemetry.track("url_resource.import_route.alert_import")
        
        // Save the imported location as a marker
        let saveHandler: (UIAlertAction) -> Void = { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            GDATelemetry.track("url_resource.import_route.save")
            
            // Reset `currentAlert` after it has been presented
            self.currentAlert = nil
            
            if SpatialDataCache.routeByKey(route.id) != nil {
                // Route already exists
                // Present another alert to ask the user what to do
                self.presentImportExistingRouteAlert(newRoute: route)
            } else {
                self.segueToEditRoute(route: route)
            }
        }
        
        // Save alert
        self.currentAlert = SoundscapeDocumentAlert.importRoute(name: route.name, saveHandler: saveHandler, cancelHandler: defaultAlertActionHandler)
        
        delegate?.stateDidChange(self)
    }
    
    private func presentImportExistingRouteAlert(newRoute: Route) {
        GDATelemetry.track("url_resource.import_route.alert_existing")
        
        let replaceHandler: (UIAlertAction) -> Void = { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            GDATelemetry.track("url_resource.import_route.replace")
            
            // Reset `currentAlert` after it has been presented
            self.currentAlert = nil
            
            self.segueToEditRoute(route: newRoute)
        }
        
        // Save alert
        self.currentAlert = SoundscapeDocumentAlert.importExistingRoute(replaceHandler: replaceHandler, cancelHandler: defaultAlertActionHandler)

        delegate?.stateDidChange(self)
    }
    
    private func presentErrorAlert() {
        GDATelemetry.track("url_resource.import_route.alert_error")
        
        // Save alert
        self.currentAlert = SoundscapeDocumentAlert.importError(dismissHandler: defaultAlertActionHandler)
        
        delegate?.stateDidChange(self)
    }
    
    // MARK: `NotificationObserver`
    
    func notificationViewController(in viewController: UIViewController) -> UIViewController? {
        return currentAlert
    }
    
}
