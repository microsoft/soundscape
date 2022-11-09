//
//  BeaconSelectionHostViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

class BeaconSelectionHostViewController: UIHostingController<AnyView> {
    required init?(coder aDecoder: NSCoder) {
        let view = BeaconSelectionView()
        
        super.init(coder: aDecoder, rootView: AnyView(view))
    }
}
