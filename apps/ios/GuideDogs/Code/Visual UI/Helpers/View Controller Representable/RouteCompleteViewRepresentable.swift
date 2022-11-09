//
//  RouteCompleteViewRepresentable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct RouteCompleteViewRepresentable: ViewControllerRepresentable {
    
    // MARK: Properties
    
    let route: RouteGuidance
    
    // MARK: `ViewControllerRepresentable`
    
    func makeViewController() -> UIViewController? {
        let navHelper = ViewNavigationHelper()
        let view = RouteCompleteView(route: route).environmentObject(navHelper)
        let hostingController = UIHostingController(rootView: AnyView(view))
        
        navHelper.host = hostingController
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.view.backgroundColor = UIColor.black.withAlphaComponent(0.60)
        hostingController.view.accessibilityViewIsModal = true
        hostingController.view.accessibilityIgnoresInvertColors = true
        
        return hostingController
    }
    
}
