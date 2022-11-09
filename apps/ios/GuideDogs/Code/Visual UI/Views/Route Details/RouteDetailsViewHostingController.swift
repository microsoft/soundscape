//
//  RouteDetailsViewHostingController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

class RouteDetailsViewHostingController: UIHostingController<AnyView> {
    required init?(coder aDecoder: NSCoder) {
        guard let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            return nil
        }
        
        let navHelper = ViewNavigationHelper()
        let view = RouteDetailsView(routeGuidance.content, deleteAction: nil)
            .environmentObject(UserLocationStore())
            .environmentObject(navHelper)
        
        super.init(coder: aDecoder, rootView: AnyView(view))
        
        navHelper.host = self
    }
}
