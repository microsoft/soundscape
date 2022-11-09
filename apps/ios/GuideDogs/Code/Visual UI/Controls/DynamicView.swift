//
//  DynamicView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

/// Base class for views that respond to changes in the content size category (e.g. Dynamic Type)
class DynamicView: UIView {
    
    /// Layout constraints that should be active when the preferredContextSizeCategory is *NOT* an accessibility size
    private var normalLayoutConstraints: [NSLayoutConstraint] = []
    
    /// Layout constraints that should be active when the preferredContextSizeCategory is an accessibility size
    private var largeLayoutConstraints: [NSLayoutConstraint] = []
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let accessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        
        if accessibilityCategory != previousTraitCollection?.preferredContentSizeCategory.isAccessibilityCategory {
            updateLayoutConstraints(accessibilityCategory)
        }
    }
    
    func setupDynamicLayoutConstraints(_ normal: [NSLayoutConstraint], _ large: [NSLayoutConstraint]) {
        normalLayoutConstraints.append(contentsOf: normal)
        largeLayoutConstraints.append(contentsOf: large)
        
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            NSLayoutConstraint.activate(largeLayoutConstraints)
        } else {
            NSLayoutConstraint.activate(normalLayoutConstraints)
        }
    }
    
    /// This method is called when the current `preferredContextSizeCategory` switches from not being an accessibility
    /// category to being an accessibility category and vice versa. By default, it toggles the `normalLayoutConstraints`
    /// and `largeLayoutConstraints` on and off appropriately given the current `preferredContentSizeCategory`. During
    /// view initialization, add constraints to these arrays so that they can be activated and deactivated automatically.
    /// If you need to make additional visual changes outside of switching constraints, override this method (ensuring you
    /// call `super.updateLayoutConstraints(_:)`).
    ///
    /// - Parameter forAccessibilityCategory: True if the current `preferredContentSizeCategory` is an accessibility category. False otherwise.
    func updateLayoutConstraints(_ forAccessibilityCategory: Bool) {
        if forAccessibilityCategory {
            NSLayoutConstraint.deactivate(normalLayoutConstraints)
            NSLayoutConstraint.activate(largeLayoutConstraints)
        } else {
            NSLayoutConstraint.deactivate(largeLayoutConstraints)
            NSLayoutConstraint.activate(normalLayoutConstraints)
        }
    }
}
