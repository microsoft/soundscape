//
//  ShareAlertFactory.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

protocol ShareAlertFactory: AlertFactory { }

extension ShareAlertFactory {
    
    // MARK: Error Alerts
    
    static func shareError(dismissHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("universal_links.alert.error.title")
        let message = GDLocalizedString("universal_links.alert.share_error.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add action to dismiss
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler))
        
        return alert
    }
    
    // MARK: First Use Experience
    
    static func firstUseExperience(dismissHandler: ActionHandler? = nil) -> UIAlertController {
        // Initialize the alert controller
        let title = GDLocalizedString("first_use_experience.share.alert.title")
        let message = GDLocalizedString("first_use_experience.share.alert.message")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add action to dismiss
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler))
        
        return alert
    }
    
    static func firstUseExperience(dismissHandler: (() -> Void)? = nil) -> Alert {
        // Initialize text views
        let title = GDLocalizedTextView("first_use_experience.share.alert.title")
        let message = GDLocalizedTextView("first_use_experience.share.alert.message")
        let dismiss = GDLocalizedTextView("general.alert.dismiss")
        
        return Alert(title: title, message: message, dismissButton: .cancel(dismiss, action: dismissHandler))
    }
    
}
