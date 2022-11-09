//
//  RouteEditViewRepresentable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct RouteEditViewRepresentable: ViewControllerRepresentable {
    
    typealias Style = RouteEditView.Style
    
    // MARK: Properties
    
    let style: Style
    
    // MARK: `ViewControllerRepresentable`
    
    func makeViewController() -> UIViewController? {
        let navHelper = ViewNavigationHelper()
        
        let view = RouteEditView(style: style, deleteAction: nil)
            .environmentObject(navHelper)
        
        let hostingController = UIHostingController<AnyView>(rootView: AnyView(view))
        navHelper.host = hostingController
        
        return hostingController
    }
    
}
