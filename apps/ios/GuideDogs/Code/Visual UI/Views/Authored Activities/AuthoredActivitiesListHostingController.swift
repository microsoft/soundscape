//
//  AuthoredActivitiesListHostingController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

class AuthoredActivitiesListHostingController: UIHostingController<AnyView> {
    required init?(coder aDecoder: NSCoder) {
        let navHelper = ViewNavigationHelper()
        let storage = AuthoredActivityStorage(AuthoredActivityLoader.shared)
        let view = AuthoredActivitiesList().environmentObject(storage).environmentObject(navHelper)
        
        super.init(coder: aDecoder, rootView: AnyView(view))
        
        navHelper.host = self
    }
}
