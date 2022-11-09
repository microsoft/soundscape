//
//  ShareRouteActivityViewRepresentable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct ShareRouteActivityViewRepresentable: ViewControllerRepresentable {
    
    // MARK: Properties
    
    let route: RouteDetail
    
    // MARK: `ViewControllerRepresentable`
    
    func makeViewController() -> UIViewController? {
        GDATelemetry.track("share.route")
        
        return SoundscapeDocumentAlert.shareRoute(route)
    }
    
}
