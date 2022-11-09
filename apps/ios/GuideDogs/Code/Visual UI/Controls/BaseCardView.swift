//
//  BaseCardView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol CardViewDelegate: AnyObject {
    func onAccessibilityActivate() -> Bool
    func onAccessibilityDidFocus()
}

@IBDesignable
class BaseCardView: UIView {
    weak var delegate: CardViewDelegate?
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
    
    override func accessibilityActivate() -> Bool {
        return delegate?.onAccessibilityActivate() ?? false
    }
    
    override func accessibilityElementDidBecomeFocused() {
        delegate?.onAccessibilityDidFocus()
    }
}
