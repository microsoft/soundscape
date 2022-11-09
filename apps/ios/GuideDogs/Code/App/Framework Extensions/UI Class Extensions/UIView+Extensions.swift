//
//  UIView+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// MARK: Frame

extension UIView {
    var height: CGFloat {
        return bounds.size.height
    }
    
    func setHeight(_ height: CGFloat) {
        self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: height)
    }
}

// MARK: Contstraints

extension UIView {
    func constraintWithAttribute(_ attribute: NSLayoutConstraint.Attribute,
                                 _ relation: NSLayoutConstraint.Relation,
                                 to item: AnyObject,
                                 multiplier: CGFloat = 1.0,
                                 constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item, attribute: attribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintsWithAttributes(_ attributes: [NSLayoutConstraint.Attribute],
                                   _ relation: NSLayoutConstraint.Relation,
                                   to item: AnyObject,
                                   multiplier: CGFloat = 1.0,
                                   constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return attributes.map { self.constraintWithAttribute($0, relation,
                                                             to: item,
                                                             multiplier: multiplier,
                                                             constant: constant) }
    }
}

// MARK: Animations

extension UIView {
    func showAnimated(completion: ((Bool) -> Void)? = nil) {
        guard self.isHidden else {
            return
        }
        self.alpha = 0.0
        self.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: { (completed) in
            completion?(completed)
        })
    }
    
    func hideAnimated(completion: ((Bool) -> Void)? = nil) {
        guard !self.isHidden else {
            return
        }

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: { (completed) in
            self.isHidden = true
            self.alpha = 1.0
            completion?(completed)
        })
    }
}

extension UIView {
    
    static func preferredContentHeightCompressedHeight(for view: UIView) -> CGFloat {
        // Calculated `targetSize` for `UIView`
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        
        return view.systemLayoutSizeFitting(targetSize).height
    }
    
    static func preferredContentHeight(for view: UIView) -> CGFloat {
        // Calculated `targetSize` for `UIView`
        let targetSize = CGSize(width: view.bounds.width, height: view.bounds.height)
        
        return view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriority.defaultHigh, verticalFittingPriority: UILayoutPriority.defaultLow).height
    }
    
    static func preferredContentHeight(for tableView: UITableView) -> CGFloat {
        // For a table, the `targetSize` is the `tableView.contentSize`
        let targetSize = tableView.contentSize
        
        return tableView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriority.defaultHigh, verticalFittingPriority: UILayoutPriority.defaultLow).height
    }
    
}

extension UIView {
    
    @discardableResult
    static func setGroupAccessibilityElement(for container: UIView?, label: String, hint: String? = nil, traits: UIAccessibilityTraits) -> UIAccessibilityElement? {
        guard let container = container else {
            return nil
        }
        
        let element = UIAccessibilityElement(accessibilityContainer: container)
        element.accessibilityLabel = label
        element.accessibilityHint = hint
        element.accessibilityFrameInContainerSpace = CGRect(x: 0.0, y: 0.0, width: container.frame.width, height: container.frame.height)
        element.accessibilityTraits = traits
        
        container.accessibilityElements = [element]
        
        return element
    }
    
}
