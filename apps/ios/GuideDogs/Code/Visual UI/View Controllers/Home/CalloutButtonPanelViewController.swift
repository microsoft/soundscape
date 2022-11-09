//
//  CalloutButtonViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import NVActivityIndicatorView

extension NSNotification.Name {
    static let didToggleLocate = Notification.Name("DidToggleLocate")
    static let didToggleOrientate = Notification.Name("DidToggleOrientate")
    static let didToggleLookAhead = Notification.Name("DidToggleLookAhead")
    static let didToggleMarkedPoints = Notification.Name("DidToggleMarkedPoints")
}

class CalloutButtonPanelViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var buttonLabels: [UILabel]!
    
    // Buttons
    @IBOutlet weak var locateContainer: UIView!
    @IBOutlet weak var orientContainer: UIView!
    @IBOutlet weak var exploreContainer: UIView!
    @IBOutlet weak var markedPointsContainer: UIView!
    
    // Images
    @IBOutlet weak var locateImageView: UIImageView!
    @IBOutlet weak var orientateImageView: UIImageView!
    @IBOutlet weak var exploreImageView: UIImageView!
    @IBOutlet weak var markedPointImageView: UIImageView!
    
    // Button Animations
    @IBOutlet weak var locateAnimation: NVActivityIndicatorView!
    @IBOutlet weak var orientateAnimation: NVActivityIndicatorView!
    @IBOutlet weak var exploreAnimation: NVActivityIndicatorView!
    @IBOutlet weak var markedPointsAnimation: NVActivityIndicatorView!
    
    var logContext: String?
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure header
        headerLabel.text = GDLocalizedString("callouts.panel.title").uppercasedWithAppLocale()
                
        configureButtonLabels()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDidToggleLocateNotification), name: Notification.Name.didToggleLocate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDidToggleOrientateNotification), name: Notification.Name.didToggleOrientate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDidToggleLookAheadNotification), name: Notification.Name.didToggleLookAhead, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDidToggleMarkedPointsNotification), name: Notification.Name.didToggleMarkedPoints, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = preferredContentSize.width
        let height = UIView.preferredContentHeightCompressedHeight(for: view)
        
        preferredContentSize = CGSize(width: width, height: height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let element = UIView.setGroupAccessibilityElement(for: locateContainer,
                                                             label: GDLocalizedString("directions.my_location"),
                                                             hint: GDLocalizedString("ui.action_button.my_location.acc_hint"),
                                                             traits: [.button]) {
            element.accessibilityIdentifier = "btn.mylocation"
        }
        
        if let element = UIView.setGroupAccessibilityElement(for: orientContainer,
                                                             label: GDLocalizedString("help.orient.page_title"),
                                                             hint: GDLocalizedString("ui.action_button.around_me.acc_hint"),
                                                             traits: [.button]) {
            element.accessibilityIdentifier = "btn.aroundme"
        }
        
        if let element = UIView.setGroupAccessibilityElement(for: exploreContainer,
                                                             label: GDLocalizedString("help.explore.page_title"),
                                                             hint: GDLocalizedString("ui.action_button.ahead_of_me.acc_hint"),
                                                             traits: [.button]) {
            element.accessibilityIdentifier = "btn.aheadofme"
        }
        
        if let element = UIView.setGroupAccessibilityElement(for: markedPointsContainer,
                                                             label: GDLocalizedString("callouts.nearby_markers"),
                                                             hint: GDLocalizedString("ui.action_button.nearby_markers.acc_hint"),
                                                             traits: [.button]) {
            element.accessibilityIdentifier = "btn.nearbymarkers"
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configureButtonLabels()
    }
    
    private func configureButtonLabels() {
        // When the font is scaled to an accessibility size, we need to use a slightly smaller text
        // style to prevent text from getting cut off in the callout button panel
        let font = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ?
            UIFont.preferredFont(forTextStyle: .caption2) :
            UIFont.preferredFont(forTextStyle: .footnote)
        
        buttonLabels.forEach { ( label) in
            label.font = font
        }
    }
    
    // MARK: `IBAction`
    
    @IBAction private func onLocateTouchUpInside(_ sender: AnyObject?) {
        updateAnimation(locateImageView, locateAnimation, true)
        
        let completion: (Bool) -> Void = { [weak self] _ in
            guard let imageView = self?.locateImageView else {
                return
            }
            
            guard let animationView = self?.locateAnimation else {
                return
            }
            
            self?.updateAnimation(imageView, animationView, false)
        }
        
        let event: Event
        
        if let preview = AppContext.shared.eventProcessor.activeBehavior as? PreviewBehavior<IntersectionDecisionPoint> {
            event = PreviewMyLocationEvent(current: preview.currentDecisionPoint.value, completionHandler: completion)
        } else {
            event = ExplorationModeToggled(.locate, sender: sender, logContext: logContext, completion: completion)
        }
        
        AppContext.process(event)
    }
    
    @IBAction private func onOrientateTouchUpInside(_ sender: AnyObject?) {
        updateAnimation(orientateImageView, orientateAnimation, true)

        AppContext.process(ExplorationModeToggled(.aroundMe, sender: sender, logContext: logContext) { [weak self] _ in
            guard let imageView = self?.orientateImageView else {
                return
            }
            
            guard let animationView = self?.orientateAnimation else {
                return
            }
            
            self?.updateAnimation(imageView, animationView, false)
        })
    }
    
    @IBAction private func onLookAheadTouchUpInside(_ sender: AnyObject?) {
        updateAnimation(exploreImageView, exploreAnimation, true)
        
        AppContext.process(ExplorationModeToggled(.aheadOfMe, sender: sender, logContext: logContext) { [weak self] _ in
            guard let imageView = self?.exploreImageView else {
                return
            }
            
            guard let animationView = self?.exploreAnimation else {
                return
            }
            
            self?.updateAnimation(imageView, animationView, false)
        })
    }
    
    @IBAction private func onMarkedPointsTouchUpInside(_ sender: AnyObject?) {
        updateAnimation(markedPointImageView, markedPointsAnimation, true)
        
        AppContext.process(ExplorationModeToggled(.nearbyMarkers, sender: sender, logContext: logContext) { [weak self] _ in
            guard let imageView = self?.markedPointImageView else {
                return
            }
            
            guard let animationView = self?.markedPointsAnimation else {
                return
            }
            
            self?.updateAnimation(imageView, animationView, false)
        })
    }
    
    // MARK: Notifications
    
    @objc func handleDidToggleLocateNotification(_ notification: Notification) {
        onLocateTouchUpInside(notification.object as AnyObject?)
    }
    
    @objc func handleDidToggleOrientateNotification(_ notification: Notification) {
        onOrientateTouchUpInside(notification.object as AnyObject?)
    }
    
    @objc func handleDidToggleLookAheadNotification(_ notification: Notification) {
        onLookAheadTouchUpInside(notification.object as AnyObject?)
    }
    
    @objc func handleDidToggleMarkedPointsNotification(_ notification: Notification) {
        onMarkedPointsTouchUpInside(notification.object as AnyObject?)
    }
    
    // MARK: Button Animations
    
    fileprivate func updateAnimation(_ imageView: UIImageView, _ animationView: NVActivityIndicatorView, _ show: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard show != animationView.isAnimating else {
                return
            }
            
            self.stopButtonAnimations()
            imageView.isHidden = show
            
            if show {
                animationView.startAnimating()
            } else {
                animationView.stopAnimating()
            }
        }
    }
    
    private func stopButtonAnimations() {
        if locateAnimation.isAnimating {
            locateAnimation.stopAnimating()
            locateImageView.isHidden = false
        }
        
        if markedPointsAnimation.isAnimating {
            markedPointsAnimation.stopAnimating()
            markedPointImageView.isHidden = false
        }
        
        if orientateAnimation.isAnimating {
            orientateAnimation.stopAnimating()
            orientateImageView.isHidden = false
        }
        
        if exploreAnimation.isAnimating {
            exploreAnimation.stopAnimating()
            exploreImageView.isHidden = false
        }
    }
    
}
