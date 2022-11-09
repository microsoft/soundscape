//
//  TintedImageView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

/// A `UIImageView` subclass that allows for specific tint colors for normal and highlighted states
@IBDesignable class TintedImageView: UIImageView {
    
    /// The tint color to use when `isHighlighted` is false
    @IBInspectable var normalTintColor: UIColor? {
        didSet {
            configureTintColor()
        }
    }
    
    /// The tint color to use when `isHighlighted` is true
    @IBInspectable var highlightedTintColor: UIColor? {
        didSet {
            configureTintColor()
        }
    }
    
    override open var isHighlighted: Bool {
        didSet {
            configureTintColor()
        }
    }
    
    override var image: UIImage? {
        didSet {
            configureTintColor()
        }
    }
    
    private func configureTintColor() {
        guard let image = self.image else { return }
        
        // If the image is not rendered as a template, it could not be tinted.
        if image.renderingMode != .alwaysTemplate {
            self.image = image.withRenderingMode(.alwaysTemplate)
        }
        
        tintColor = isHighlighted ? highlightedTintColor : normalTintColor
    }
    
}
