//
//  BorderedIcon.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

@IBDesignable
class BorderedIcon: UIImageView {
    @IBInspectable var cornerRadius: CGFloat = 5.0
    @IBInspectable var borderWidth: CGFloat = 1.0
    @IBInspectable var borderColor: UIColor = UIColor.white
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
}
