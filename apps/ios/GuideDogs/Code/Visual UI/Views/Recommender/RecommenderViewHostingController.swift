//
//  RecommenderViewHostingController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import CocoaLumberjackSwift

class RecommenderViewHostingController: UIHostingController<AnyView> {
    
    required init?(coder aDecoder: NSCoder) {
        let navHelper = ViewNavigationHelper()
        let view = RecommenderView(viewModel: RecommenderViewModel())
            .environmentObject(navHelper)
        
        super.init(coder: aDecoder, rootView: AnyView(view))
        
        super.view.backgroundColor = UIColor.clear
        
        navHelper.host = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.sizeToFit()
        preferredContentSize.height = view.bounds.height
    }
    
}
