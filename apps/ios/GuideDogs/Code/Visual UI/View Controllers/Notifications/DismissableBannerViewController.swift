//
//  DissmissableBannerViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class DismissableBannerViewController: BannerViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var activateButton: UIButton!
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add a custom accessibility action to dismiss the banner
        let action = UIAccessibilityCustomAction(name: GDLocalizedString("general.alert.dismiss"), target: self, selector: #selector(self.dismissBanner))
        accessibilityCustomActions = [ action ]
        
        dismissButton.accessibilityElementsHidden = true
    }
    
    // MARK: Actions
    
    @IBAction func onDismissTouchUpInside() {
        dismissBanner()
    }
    
    @objc
    private func dismissBanner() {
        GDATelemetry.track("banner_dismissed", with: ["nibName": nibName ?? "unknown"])
        
        delegate?.didDismiss(self)
    }
    
}
