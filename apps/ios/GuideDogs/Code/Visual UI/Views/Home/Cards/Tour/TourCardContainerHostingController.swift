//
//  TourCardContainerHostingController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

class TourCardContainerHostingController: UIHostingController<AnyView> {
    
    var style: BeaconStyle!
    
    required init?(coder aDecoder: NSCoder) {
        guard let tour = AppContext.shared.eventProcessor.activeBehavior as? GuidedTour else {
            // Unexpected state
            super.init(coder: aDecoder, rootView: AnyView(EmptyView()))
            return
        }
        
        let navHelper = ViewNavigationHelper()
        let view = TourCardContainer(tour: tour)
            .environmentObject(UserLocationStore())
            .environmentObject(navHelper)
            .colorPalette(Palette.Theme.teal)
        
        super.init(coder: aDecoder, rootView: AnyView(view))
        
        self.view.backgroundColor = .clear
        
        navHelper.host = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = UIView.preferredContentHeightCompressedHeight(for: view)
        preferredContentSize.height = height
        
        self.view.invalidateIntrinsicContentSize()
    }
    
}
