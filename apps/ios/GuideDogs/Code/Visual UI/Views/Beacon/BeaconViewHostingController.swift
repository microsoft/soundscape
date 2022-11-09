//
//  BeaconViewHostingController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

class BeaconViewHostingController: UIHostingController<AnyView> {
    
    required init?(coder aDecoder: NSCoder) {
        let navHelper = ViewNavigationHelper()
        
        let view = BeaconView()
            .environmentObject(BeaconDetailStore())
            .environmentObject(UserLocationStore())
            .environmentObject(navHelper)
        
        super.init(coder: aDecoder, rootView: AnyView(view))
        
        navHelper.host = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = UIView.preferredContentHeightCompressedHeight(for: view)
        preferredContentSize.height = height
        
        self.view.invalidateIntrinsicContentSize()
    }
    
}
