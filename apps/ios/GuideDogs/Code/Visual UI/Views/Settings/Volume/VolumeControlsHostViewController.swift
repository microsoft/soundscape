//
//  VolumeControlsHostViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

class VolumeControlsHostViewController: UIHostingController<AnyView> {
    required init?(coder aDecoder: NSCoder) {
        let view = VolumeControls()
        
        super.init(coder: aDecoder, rootView: AnyView(view))
    }
}
