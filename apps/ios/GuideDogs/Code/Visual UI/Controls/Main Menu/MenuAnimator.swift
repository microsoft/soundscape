//
//  MenuAnimator
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class MenuAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let style: AnimationStyle
    let completedCallback: ((_ finished: Bool) -> Void)?
    
    enum AnimationStyle {
        case open
        case close
    }
    
    init(_ style: AnimationStyle, callback: ((_ finished: Bool) -> Void)? = nil) {
        self.style = style
        self.completedCallback = callback
        
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.40
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch style {
        case .open:  openMenu(using: transitionContext)
        case .close: closeMenu(using: transitionContext)
        }
    }
    
    private func openMenu(using transitionContext: UIViewControllerContextTransitioning) {
        guard let vc = transitionContext.viewController(forKey: .to) else {
            completedCallback?(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        containerView.addSubview(vc.view)
        
        // Setup frame, constraints, and transform (for moving menu offscreen before animating onscreen)
        vc.view.frame = containerView.frame
        vc.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        vc.view.transform = CGAffineTransform(translationX: -vc.view.frame.width, y: 0.0)
        
        // Animate the menu onscreen
        let animations = {
            vc.view.transform = CGAffineTransform.identity
        }
        
        UIView.animate(withDuration: duration, animations: animations) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            self.completedCallback?(finished)
        }
        
    }
    
    private func closeMenu(using transitionContext: UIViewControllerContextTransitioning) {
        guard let vc = transitionContext.viewController(forKey: .from) else {
            completedCallback?(false)
            return
        }
        
        // Animate the menu offscreen
        let animations = {
            vc.view.transform = CGAffineTransform(translationX: -vc.view.frame.width, y: 0.0)
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: animations) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
            if finished {
                vc.view.removeFromSuperview()
            }
            
            self.completedCallback?(finished)
        }
    }
}
