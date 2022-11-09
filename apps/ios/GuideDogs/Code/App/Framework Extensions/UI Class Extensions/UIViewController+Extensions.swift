//
//  UIViewController+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

extension UIViewController {
    
    /// Returns true if the current view controller or it's navigation controller is presented modally.
    var isPresentedModally: Bool {
        return presentingViewController != nil || navigationController?.presentingViewController != nil
    }
    
    var isPresentingModal: Bool {
        return presentedViewController != nil || navigationController?.presentedViewController != nil
    }
    
    // Returns the visible `presentedViewController`.
    // Returns `nil` if `presentedViewController` is `nil`.
    var visiblePresentedViewController: UIViewController? {
        guard var visible = presentedViewController else { return nil }
        var next = visible.presentedViewController
        
        while next != nil {
            visible = next!
            next = next!.presentedViewController
        }
        
        return visible
    }
    
    /// Add a child view controller. Calls the appropriate methods to add the child's
    /// view as a subview and to inform the child view controller that it has been
    /// moved to this view controller as its parent.
    ///
    /// - Parameter child: The child view controller
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    /// Add a child view controller. Calls the appropriate methods to add the child's
    /// view as a subview and to inform the child view controller that it has been
    /// moved to this view controller as its parent.
    ///
    /// - Parameters:
    ///   - child: The child view controller
    ///   - constraints: Constraints for the child view controller's view
    func add(_ child: UIViewController, constraints: (UIView) -> [NSLayoutConstraint]) {
        addChild(child)
        view.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        child.didMove(toParent: self)
        NSLayoutConstraint.activate(constraints(child.view))
    }
    
    /// Removes this view controller from its parent view controller. Ensures that this
    /// view controller is informed of the pending move away from its parent and then
    /// removes its view before removing it from its parent view controller.
    func remove() {
        guard parent != nil else {
            return
        }
        
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    func isPresentingAlert(presentedAlertController: UIAlertController) -> Bool {
        return (self.presentedViewController as? UIAlertController) != nil &&
            (self.presentedViewController as? UIAlertController) == presentedAlertController
    }
    
}
