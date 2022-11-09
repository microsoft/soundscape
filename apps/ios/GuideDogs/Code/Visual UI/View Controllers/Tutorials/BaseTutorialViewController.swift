//
//  BaseTutorialViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

// MARK: Types

struct Tutorial {
    let pages: [Page]
}

struct Page {
    let title: String
    let image: UIImage
    let text: String
    let buttonTitle: String?
    let buttonAction: Selector?
}

// MARK: - Notification Names

extension Notification.Name {
    static let disableMagicTap = Notification.Name("GDADisableMagicTap")
    static let enableMagicTap = Notification.Name("GDAEnableMagicTap")
}

// MARK: -

class BaseTutorialViewController: UIViewController {

    // MARK: Properties
    
    @IBOutlet weak var pageTextLabel: UILabel!
    
    var pageFinished = false
    
    // MARK: Playing Content

    internal func play(delay: TimeInterval = 0.0, text: String, _ completion: ((Bool) -> Void)? = nil) {
        let playInternal = { [weak self] (_ text: String, _ completion: ((Bool) -> Void)?) in
            guard let `self` = self else {
                completion?(false)
                return
            }

            guard !self.pageFinished else {
                completion?(false)
                return
            }
            
            // Update UI
            self.updatePageText(text)
            
            // Play audio
            AppContext.process(GenericAnnouncementEvent(text, completionHandler: completion))
        }
        
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playInternal(text) { (success) in
                    DispatchQueue.main.async {
                        completion?(success)
                    }
                }
            }
        } else {
            playInternal(text) { (success) in
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }
    
    internal func playRepeated(_ text: String, _ delay: TimeInterval, _ shouldCancel: @escaping () -> Bool, _ completion: ((Bool) -> Void)? = nil) {
        // Only schedule the repeat if the cancelation condition is not already met
        guard !shouldCancel() else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            // Only repeat the instructions if the cancelation condition is still not met
            guard !shouldCancel() else {
                return
            }
            
            self?.play(text: text) { (finished) in
                completion?(finished)
                
                // Schedule the same instructions to repeat again if need be
                self?.playRepeated(text, delay, shouldCancel, completion)
            }
        }
    }
    
    internal func stop() {
        AppContext.shared.eventProcessor.hush(playSound: false)
    }
    
    internal func updatePageText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard self.pageTextLabel.text != text else {
                return
            }
            
            let animations: (() -> Void) = { [weak self] in
                self?.pageTextLabel.text = text
            }
            
            UIView.transition(with: self.pageTextLabel, duration: 0.50, options: .transitionCrossDissolve, animations: animations, completion: nil)
        }
    }
    
    // MARK: Handle other app audio
    
    internal func toggleAppCalloutsOn() {
        if !SettingsContext.shared.automaticCalloutsEnabled {
            AppContext.process(ToggleAutoCalloutsEvent(playSound: false))
        }
    }
    
    internal func toggleAppCalloutsOff() {
        if SettingsContext.shared.automaticCalloutsEnabled {
            AppContext.process(ToggleAutoCalloutsEvent(playSound: false))
        }
    }
    
    // MARK: Accessibility

    override func accessibilityPerformMagicTap() -> Bool {
        // Intercept magic taps by default
        return true
    }
    
}
