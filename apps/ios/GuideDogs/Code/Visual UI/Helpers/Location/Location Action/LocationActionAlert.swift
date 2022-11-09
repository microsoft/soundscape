//
//  LocationActionAlert.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct LocationActionAlert {
    
    // MARK: `typealias`
    
    typealias ActionHandler = (UIAlertAction) -> Void
    
    // MARK: Properties
    
    private static let title = GDLocalizedString("universal_links.alert.error.title")
    
    // MARK: Alerts
    
    static func alert(for error: LocationActionError, dismissHandler: ActionHandler? = nil) -> UIAlertController {
        return ErrorAlerts.buildGeneric(title: title, message: error.localizedDescription, dismissHandler: dismissHandler)
    }
    
    static func alert(for error: Error, dismissHandler: ActionHandler? = nil) -> UIAlertController {
        if let error = error as? LocationActionError {
            return alert(for: error, dismissHandler: dismissHandler)
        }
        
        return ErrorAlerts.buildGeneric(title: title, message: nil, dismissHandler: dismissHandler)
    }
    
    static func restartPreview(previewHandler: ActionHandler?) -> UIAlertController {
        let alert = UIAlertController(title: GDLocalizedString("preview.alert.restart.title"),
                                      message: GDLocalizedString("preview.alert.restart.message"),
                                      preferredStyle: .alert)
        
        let previewAction = UIAlertAction(title: GDLocalizedString("preview.alert.restart.button"), style: .default, handler: previewHandler)
        alert.addAction(previewAction)
        alert.preferredAction = previewAction
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: nil))
        
        return alert
    }
    
}
