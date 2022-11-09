//
//  OfflineHelpPageViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class OfflineHelpPageViewController: UIViewController {
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("help.offline")
    }
    
}

extension OfflineHelpPageViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}
