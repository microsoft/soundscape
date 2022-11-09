//
//  RoundedSolidButton.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

@IBDesignable
class RoundedSolidButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 5.0
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                backgroundColor = backgroundColor?.withAlphaComponent(1.0)
            } else {
                backgroundColor = backgroundColor?.withAlphaComponent(0.3)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        
        if !isEnabled {
            backgroundColor = backgroundColor?.withAlphaComponent(0.3)
        }
    }
}
