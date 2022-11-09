//
//  BeaconTitleContentView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class BeaconTitleContentView: UIView {
    
    // MARK: Properties
    
    weak var delegate: BeaconTitleContentViewDelegate?
    
    // MARK: Accessibility
    
    override func accessibilityActivate() -> Bool {
        super.accessibilityActivate()
        
        delegate?.onAccessibilityActivate()
        
        return true
    }
    
    override func accessibilityElementDidLoseFocus() {
        super.accessibilityElementDidLoseFocus()
        
        delegate?.onAccessibilityElementDidLoseFocus()
    }
    
}
