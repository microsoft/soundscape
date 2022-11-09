//
//  LaunchHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CocoaLumberjackSwift
import SwiftUI

extension Notification.Name {
    static let appDidInitialize = Notification.Name("GDAAppDidInitialize")
    static let magicTapOccurred = Notification.Name("GDAMagicTapOccurred")
}

class LaunchHelper {
    
    enum LaunchStoryboard: String {
        case main = "main"
        case firstLaunch = "FirstLaunch"
    }
    
    fileprivate static var windowConfigured: Bool = false
    fileprivate static var magicTapEnabled: Bool = true
    
    class func configureAppView(with launchStoryboard: LaunchStoryboard) {
        guard let window = UIApplication.shared.windows.first(where: \.isKeyWindow) else {
            return
        }
        
        window.configureWindow()
        
        let rootVC: UIViewController
        
        if launchStoryboard == .firstLaunch { // SwiftUI
            // Initialize view model and set dismiss handler
            let viewModel = OnboardingViewModel {
                LaunchHelper.configureAppView(with: .main)
            }
            
            let rootView = OnboardingWelcomeView(context: .firstUse).environmentObject(viewModel)
            rootVC = UIHostingController(rootView: rootView)
        } else { // UIKit
            let storyboard = UIStoryboard(name: launchStoryboard.rawValue, bundle: nil)
                    
            // Make sure we can load the initial view controller from this storyboard
            guard let viewController = storyboard.instantiateInitialViewController() else {
                return
            }
            
            rootVC = viewController
            
            NotificationCenter.default.post(name: NSNotification.Name.appDidInitialize, object: nil)
        }
        
        window.replaceRootViewControllerWith(rootVC, animated: true, completion: nil)
    }
}

extension UIWindow {
    /// Use this method to change the `rootViewController` of the app's main window. This method
    /// will properly dismiss the current view controller (if one exists) before setting the
    /// replacement view controller.
    ///
    /// - Parameters:
    ///   - replacementController: A new view controller to set to `rootViewController`
    ///   - animated: Should the transition be animated
    ///   - completion: Callback invoked on completion
    fileprivate func replaceRootViewControllerWith(_ newRoot: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let currentRoot = rootViewController else {
            rootViewController = newRoot
            return
        }
        
        guard let snapshot = snapshotView(afterScreenUpdates: true) else {
            rootViewController = newRoot
            return
        }
        
        addSubview(snapshot)
        
        let dismissCompletion = { [weak self] () -> Void in // dismiss all modal view controllers
            guard let `self` = self else {
                return
            }
            
            self.rootViewController = newRoot
            self.bringSubviewToFront(snapshot)
            
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    snapshot.alpha = 0
                }, completion: { (_) in
                    snapshot.removeFromSuperview()
                    completion?()
                })
            } else {
                snapshot.removeFromSuperview()
                completion?()
            }
        }
        
        if currentRoot.presentedViewController != nil {
            currentRoot.dismiss(animated: false, completion: dismissCompletion)
        } else {
            dismissCompletion()
        }
    }
    
    // MARK: Configuration
    
    fileprivate func configureWindow() {
        guard !LaunchHelper.windowConfigured else {
            return
        }
        
        self.isOpaque = true
        self.backgroundColor = UIColor.black
        self.clipsToBounds = true
        
        let doubleTapGR = UITapGestureRecognizer(target: self, action: #selector(self.handleMagicTap))
        doubleTapGR.numberOfTapsRequired = 2
        doubleTapGR.numberOfTouchesRequired = 2
        self.addGestureRecognizer(doubleTapGR)
        
        NotificationCenter.default.addObserver(self, selector: #selector(disableMagicTap), name: NSNotification.Name.disableMagicTap, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enableMagicTap), name: NSNotification.Name.enableMagicTap, object: nil)
        
        LaunchHelper.windowConfigured = true
    }
    
    // MARK: Actions
    
    override open func accessibilityPerformMagicTap() -> Bool {
        return handleMagicTap()
    }
    
    @objc fileprivate func handleMagicTap() -> Bool {
        guard LaunchHelper.magicTapEnabled else {
            return false
        }
        
        // Hush callouts
        AppContext.shared.eventProcessor.toggleAudio()
        
        NotificationCenter.default.post(name: NSNotification.Name.magicTapOccurred, object: self)
        
        return true
    }
    
    @objc func disableMagicTap() {
        LaunchHelper.magicTapEnabled = false
    }
    
    @objc func enableMagicTap() {
        LaunchHelper.magicTapEnabled = true
    }

    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        // We use the shake motion to pause and resume a GPX simulation
        guard FeatureFlag.isEnabled(.developerTools),
            motion == .motionShake,
            AppContext.shared.geolocationManager.isSimulatingGPX else {
                return
        }
        
        DDLogInfo("Shake motion detected")
        
        guard let gpxSimulator = AppContext.shared.geolocationManager.gpxSimulator else { return }
        gpxSimulator.toggleSimulationState()
        
        let generator = UINotificationFeedbackGenerator()
        
        if gpxSimulator.isPaused {
            generator.notificationOccurred(.error)
        } else {
            generator.notificationOccurred(.success)
        }
    }
    
}
