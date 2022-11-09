//
//  Alert+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

extension Alert {
    
    static func deleteMarkerAlert(markerId: String,
                                  deleteAction: @escaping (() -> Void),
                                  cancelAction: @escaping (() -> Void) = {}) -> Alert {
        let message: Text
        let routes = SpatialDataCache.routesContaining(markerId: markerId)
        if routes.isEmpty {
            message = GDLocalizedTextView("general.alert.destructive_undone_message")
        } else {
            let routNames = routes.map { $0.name }.joined(separator: "\n")
            message = GDLocalizedTextView("markers.destructive_delete_message.routes", routNames)
        }
        
        return Alert(title: GDLocalizedTextView("markers.destructive_delete_message"),
                     message: message,
                     primaryButton: .cancel(GDLocalizedTextView("general.alert.cancel"), action: cancelAction),
                     secondaryButton: .destructive(GDLocalizedTextView("general.alert.delete"), action: deleteAction))
    }
    
}
