//
//  SoundscapeDocumentAlert.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct SoundscapeDocumentAlert: ShareAlertFactory {
    
    // MARK: Error Alerts
    
    static func importError(dismissHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("universal_links.alert.error.title")
        let message = GDLocalizedString("url_resource.alert.route.import_error.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add action to dismiss
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler))
        
        return alert
    }
    
    // MARK: Import Alerts
    
    static func importRoute(name: String, saveHandler: ActionHandler? = nil, cancelHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("url_resource.alert.route.import.title", name)
        let message = GDLocalizedString("url_resource.alert.route.import.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        // Add action to save route
        let saveAction = UIAlertAction(title: GDLocalizedString("url_resource.alert.route.import.save"), style: .default, handler: saveHandler)
        alert.addAction(saveAction)
        alert.preferredAction = saveAction
        
        // Add cancel action
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: cancelHandler))
        
        return alert
    }
    
    static func importExistingRoute(replaceHandler: ActionHandler? = nil, cancelHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("url_resource.alert.route.import_existing.title")
        let message = GDLocalizedString("url_resource.alert.route.import_existing.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add action to replace the existing marker
        let replace = UIAlertAction(title: GDLocalizedString("general.alert.replace"), style: .default, handler: replaceHandler)
        alert.addAction(replace)
        alert.preferredAction = replace
        
        // Add cancel action
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: cancelHandler))
        
        return alert
    }
    
    // MARK: Share Activity View Controllers
    
    private static func shareRoute(_ url: URL, routeName: String) -> UIActivityViewController? {
        let message = GDLocalizedString("url_resource.alert.route.share.message", routeName)
        let items: [Any] = [message, url]
        
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Remove the temporary file after the alert has been dismissed
        activity.completionWithItemsHandler = {(_, _, _, _) in
            URLResourceManager.removeURLResource(at: url)
        }
        
        return activity
    }
    
    static func shareRoute(_ route: Route) -> UIActivityViewController? {
        guard let url = URLResourceManager.shareRoute(route) else {
            return nil
        }
        
        return shareRoute(url, routeName: route.name)
    }
    
    static func shareRoute(_ routeDetail: RouteDetail) -> UIActivityViewController? {
        guard case .database(let id) = routeDetail.source else {
            return nil
        }
        
        guard let route = SpatialDataCache.routeByKey(id) else {
            return nil
        }
        
        return shareRoute(route)
    }
    
}
