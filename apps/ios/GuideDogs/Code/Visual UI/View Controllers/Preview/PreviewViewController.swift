//
//  PreviewViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

class PreviewViewController: UIViewController {
    
    // MARK: Segues
    
    private struct Segue {
        static let showPOISelection = "ShowPOISelection"
    }
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var smallBannerContainerView: UIView!
    @IBOutlet weak var smallBannerContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var virtualLocationView: UIView!
    @IBOutlet var virtualLocationHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var tutorialContainerView: UIView!
    @IBOutlet weak var exitBarButtonItem: UIBarButtonItem!
    @IBOutlet var calloutPanelContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var cardContainerViewHeightConstraint: NSLayoutConstraint!
    var roadToggleButton: UIBarButtonItem!
    
    // MARK: Properties
    
    private var virtualLocationViewController: VirtualLocationViewController?
    private weak var calloutButtonViewController: CalloutButtonPanelViewController?
    private weak var activityIndicatorViewController: PreviewActivityIndicatorViewController?
    private var isActivatedAndStartedSubscriber: AnyCancellable?
    private var isStoppedAndDeactivatedSubscriber: AnyCancellable?
    private var userActionSubscriber: AnyCancellable?
    private var isActivatedAndStarted = false
    private var isRestarting = false
    private var isPresentingTutorialViewController = false
    private var initializationResult: LocationActionHandler.PreviewResult?
    var onDismissHandler: (() -> Void)?
    
    /// Holds the user action notification until the preview controller is active and started
    private var pendingUserActionNotification: Notification?
    
    var locationDetail: LocationDetail? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            // Save new state
            isRestarting = true
            
            // Deactivate the current behavior experience
            // Once deactivation is complete, the preview
            // experience will be re-started at the new location
            stop()
        }
    }
    
    private var behavior: PreviewBehavior<IntersectionDecisionPoint>? {
        didSet {
            guard oldValue?.id != behavior?.id else {
                return
            }
            
            virtualLocationViewController?.behavior = behavior
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        
        // Initialize the road toggle button (this handles initial creation - all further updates are
        // handled by `configureToggleButton()`
        if SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads {
            roadToggleButton = UIBarButtonItem(image: UIImage(named: "preview_toggle_on"), style: .plain, target: self, action: #selector(onRoadToggleButtonTouchUpInside))
            roadToggleButton.accessibilityLabel = GDLocalizedString("preview.include_unnamed_roads.label.on")
            roadToggleButton.accessibilityHint = GDLocalizedString("preview.include_unnamed_roads.hint.on")
        } else {
            roadToggleButton = UIBarButtonItem(image: UIImage(named: "preview_toggle_off"), style: .plain, target: self, action: #selector(onRoadToggleButtonTouchUpInside))
            roadToggleButton.accessibilityLabel = GDLocalizedString("preview.include_unnamed_roads.label.off")
            roadToggleButton.accessibilityHint = GDLocalizedString("preview.include_unnamed_roads.hint.off")
        }
        
        // Transparent navigation bar
        navigationController?.navigationBar.configureAppearance(for: .transparentLightTitle)
        
        // Embed the `VirtualLocationViewController`
        let viewController = VirtualLocationViewController()
        viewController.behavior = self.behavior
        
        // Add child view controller
        self.add(viewController)
        self.virtualLocationView.addSubview(viewController.view)
        
        // Set layout for child view controller
        viewController.view.frame = self.virtualLocationView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Ready to display
        viewController.didMove(toParent: self)
        
        // Save view controller
        virtualLocationViewController = viewController
        
        if FirstUseExperience.didComplete(.previewTutorial) == false {
            GDATelemetry.track("preview.tutorial.presented")
            
            // Update state
            isPresentingTutorialViewController = true
            
            // Configure tutorial view on first launch
            configureTutorialView(isHidden: false)
        }
        
        // Fetch required data and start the preview
        // experience at the given location
        if let locationDetail = locationDetail {
            initializePreview(at: locationDetail)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("street_preview")
        
        updateCalloutButtonTraits()
        
        // Transparent navigation bar
        navigationController?.navigationBar.configureAppearance(for: .transparentLightTitle)
        
        // Configure the toggle button view
        configureToggleButton()
        
        NSUserActivity(userAction: .streetPreview).becomeCurrent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Default navigation bar
        navigationController?.navigationBar.configureAppearance(for: .default)
    }
    
    deinit {
        // Stop updates
        isActivatedAndStartedSubscriber?.cancel()
        isStoppedAndDeactivatedSubscriber?.cancel()
        userActionSubscriber?.cancel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? PreviewTutorialViewController {
            viewController.delegate = self
        } else if let vc = segue.destination as? CalloutButtonPanelViewController {
            calloutButtonViewController = vc
            calloutButtonViewController?.logContext = "preview"
        } else if let viewController = segue.destination as? PreviewActivityIndicatorViewController {
            activityIndicatorViewController = viewController
        } else if let vc = segue.destination as? SearchTableViewController {
            vc.logContext = "preview"
            vc.onDismissPreviewHandler = onDismissHandler
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateCalloutButtonTraits()
    }
    
    private func updateCalloutButtonTraits() {
        guard let child = calloutButtonViewController else {
            return
        }
        
        // When the preferredContentSizeCategory is an accessibility size, we override the default behavior in the
        // callout button panel because of the limited available space. We cap the maximum content size category to
        // be `.accessibilityMedium`.
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            setOverrideTraitCollection(UITraitCollection(preferredContentSizeCategory: .accessibilityMedium), forChild: child)
        } else {
            setOverrideTraitCollection(nil, forChild: child)
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container is VirtualLocationViewController {
            virtualLocationHeightConstraint.constant = container.preferredContentSize.height
        }
        
        if container is CalloutButtonPanelViewController {
            calloutPanelContainerHeightConstraint.constant = container.preferredContentSize.height
        }
        
        if container is CardStateViewController {
            cardContainerViewHeightConstraint.constant = container.preferredContentSize.height
        }
    }
    
    private func initializePreview(at locationDetail: LocationDetail) {
        // Stop updates
        isActivatedAndStartedSubscriber?.cancel()
        isStoppedAndDeactivatedSubscriber?.cancel()
        userActionSubscriber?.cancel()
        
        // Reset behavior
        behavior = nil
        
        // Reset values
        isActivatedAndStarted = false
        
        let progress = LocationActionHandler.preview(locationDetail: locationDetail) { [weak self] (result) in
            guard let `self` = self else {
                return
            }
            
            if self.isPresentingTutorialViewController {
                // Save result and process after the tutorial
                // has completed
                self.initializationResult = result
            } else {
                // Process result immediately
                self.onPreviewDidInitialize(result)
            }
        }
        
        // If we are downloading data, pass the progress object to the
        // view controller
        activityIndicatorViewController?.state = .activating(progress: progress)
        
        // Configure initial view
        configureActivityIndicatorView(isHidden: isActivatedAndStarted)
    }
    
    private func onPreviewDidInitialize(_ result: Result<PreviewBehavior<IntersectionDecisionPoint>, LocationActionError>) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            switch result {
            case .success(let behavior):
                // Save behavior
                self.behavior = behavior
                // Start the preview experience
                self.onPreviewDidInitialize(behavior)
            case .failure(let error):
                // Present the error alert and dismiss the current
                // view and return home
                let alert = LocationActionAlert.alert(for: error) { (_) in
                    self.dismiss(animated: true) { [weak self] in
                        self?.onDismissHandler?()
                    }
                }
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func onPreviewDidInitialize(_ behavior: PreviewBehavior<IntersectionDecisionPoint>) {
        // Listen for an event indicating that the
        // preview behavior has been activated and started
        isActivatedAndStartedSubscriber = behavior.isStartedSubject
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] (isStarted) in
                guard let `self` = self else {
                    return
                }
                
                // Save new value
                self.isActivatedAndStarted = isStarted
                
                // Update the state of the activity indicator view
                self.configureActivityIndicatorView(isHidden: isStarted)
                
                if isStarted {
                    self.continuePendingUserActionIfNeeded()
                }
            })
        
        // Listen for an event indicating that the
        // preview behavior has been stopped and deactivated
        isStoppedAndDeactivatedSubscriber = NotificationCenter.default
            .publisher(for: .behaviorDeactivated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                if let locationDetail = self.locationDetail, self.isRestarting {
                    // Reset value
                    self.isRestarting = false
                    
                    // Fetch required data and re-start the preview
                    // experience at the given location
                    self.initializePreview(at: locationDetail)
                } else {
                    // After the behavior has been deactivated,
                    // dismiss the view and return home
                    self.dismiss(animated: true) { [weak self] in
                        self?.onDismissHandler?()
                    }
                }
        }
        
        // Listen for an event indicating that the user has continued an action
        userActionSubscriber = NotificationCenter.default
            .publisher(for: .continueUserAction)
            .receive(on: RunLoop.main)
            .sink { [weak self] (notification) in
                guard let `self` = self else { return }
                
                if self.isActivatedAndStarted {
                    self.continueUserAction(notification)
                } else {
                    self.pendingUserActionNotification = notification
                }
            }
        
        start()
    }
    
    private func configureToggleButton() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads {
                self.roadToggleButton.image = UIImage(named: "preview_toggle_on")
                self.roadToggleButton.accessibilityLabel = GDLocalizedString("preview.include_unnamed_roads.label.on")
                self.roadToggleButton.accessibilityHint = GDLocalizedString("preview.include_unnamed_roads.hint.on")
            } else {
                self.roadToggleButton.image = UIImage(named: "preview_toggle_off")
                self.roadToggleButton.accessibilityLabel = GDLocalizedString("preview.include_unnamed_roads.label.off")
                self.roadToggleButton.accessibilityHint = GDLocalizedString("preview.include_unnamed_roads.hint.off")
            }
        }
    }
    
    private func configureContainerView(_ container: UIView, isHidden: Bool, navigationBarIsHidden: Bool, roadToggleItemIsHidden: Bool) {
        DispatchQueue.main.async {
            // Update the state of the activity indicator view
            UIView.transition(with: self.view, duration: 1.0, options: .transitionCrossDissolve, animations: { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                // Hide sibling elements when a container view is presented
                container.accessibilityViewIsModal = isHidden == false
                
                // Show view
                container.isHidden = isHidden
                
                // Show or hide the road toggle button in the navigation item
                if roadToggleItemIsHidden {
                    self.navigationItem.remove(barButtonItem: self.roadToggleButton)
                } else {
                    self.navigationItem.setRightBarButton(self.roadToggleButton, animated: true)
                }
                
                // Update navigation bar
                self.navigationController?.setNavigationBarHidden(navigationBarIsHidden, animated: true)
            }, completion: { [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                
                // Ensures that Voiceover is aware of new layout
                let argument = isHidden ? self.exitBarButtonItem : container
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: argument)
            })
        }
    }
    
    private func configureActivityIndicatorView(isHidden: Bool) {
        guard isPresentingTutorialViewController == false else {
            return
        }
        
        if isHidden == false, self.navigationController?.topViewController != self {
            // Pop to this view controller before displaying the activity
            // indicator view
            self.navigationController?.popToViewController(self, animated: true)
        }
        
        configureContainerView(activityIndicatorContainerView, isHidden: isHidden, navigationBarIsHidden: false, roadToggleItemIsHidden: !isHidden)
    }
    
    private func configureTutorialView(isHidden: Bool) {
        configureContainerView(tutorialContainerView, isHidden: isHidden, navigationBarIsHidden: isHidden == false, roadToggleItemIsHidden: !isHidden)
    }
    
    // MARK: `IBAction`
    
    @IBAction func onExitSelected(_ sender: Any) {
        // Stop updates while exiting
        isActivatedAndStartedSubscriber?.cancel()
        
        // Reset value
        isRestarting = false
        
        // Disable exit button
        exitBarButtonItem.isEnabled = false
        
        stop()
    }
    
    @objc func onRoadToggleButtonTouchUpInside() {
        SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads.toggle()
        
        GDATelemetry.track("preview.include_unnamed_roads", with: ["value": "\(SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads)", "context": "preview"])
        
        // Reconfigure the view
        configureToggleButton()
    }
    
    @IBAction func unwindToPreview(segue: UIStoryboardSegue) { }
    
    // MARK: Preview
    
    private func start() {
        guard AppContext.shared.eventProcessor.activeBehavior.id != behavior?.id else {
            return
        }
        
        guard let behavior = behavior else {
            return
        }
        
        // Show the activity indicator view while activating
        // and starting the behavior
        configureActivityIndicatorView(isHidden: false)
        
        // Activate the preview behavior
        AppContext.shared.eventProcessor.activateCustom(behavior: behavior)
    }
    
    private func stop() {
        if let behavior = behavior {
            guard AppContext.shared.eventProcessor.activeBehavior.id == behavior.id else {
                return
            }
            
            // Do not display progress while deactivating
            activityIndicatorViewController?.state = .deactivating
            
            // Show the activity indicator view while stopping
            // and deactivating the behavior
            configureActivityIndicatorView(isHidden: false)
            
            // Deactivate the preview behavior
            AppContext.shared.eventProcessor.deactivateCustom()
        } else {
            // There is no behavior to deactivate (it might be initializing)
            // Dismiss the view and return home
            self.dismiss(animated: true) { [weak self] in
                self?.onDismissHandler?()
            }
        }
    }
    
    // MARK: User Actions
    
    private func continueUserAction(_ notification: Notification) {
        guard let userAction = notification.userInfo?[UserActionManager.Keys.userAction] as? UserAction else { return }
        
        GDLogAppInfo("Continuing user action: \(userAction.rawValue) (street preview)")
        
        switch userAction {
        case .myLocation:
            calloutButtonViewController?.handleDidToggleLocateNotification(notification)
        case .aroundMe:
            calloutButtonViewController?.handleDidToggleOrientateNotification(notification)
        case .aheadOfMe:
            calloutButtonViewController?.handleDidToggleLookAheadNotification(notification)
        case .nearbyMarkers:
            calloutButtonViewController?.handleDidToggleMarkedPointsNotification(notification)
        case .search:
            self.performSegue(withIdentifier: Segue.showPOISelection, sender: userAction)
        case .saveMarker:
            // Not supported in street preview
            break
        case .streetPreview:
            // Already in street preview
            break
        }
    }
    
    private func continuePendingUserActionIfNeeded() {
        guard let pendingUserActionNotification = pendingUserActionNotification else { return }
        continueUserAction(pendingUserActionNotification)
        self.pendingUserActionNotification = nil
    }
    
}

// MARK: - PreviewTutorialDelegate

extension PreviewViewController: PreviewTutorialDelegate {
    
    func previewTutorialDidComplete() {
        GDATelemetry.track("preview.tutorial.dismissed")
        
        // Update state
        isPresentingTutorialViewController = false
        
        if let initializationResult = initializationResult {
            // Process result
            onPreviewDidInitialize(initializationResult)
            
            // Reset value
            self.initializationResult = nil
        }
        
        configureTutorialView(isHidden: true)
        configureActivityIndicatorView(isHidden: false)
    }
    
}

// MARK: - LargeBannerContainerView

extension PreviewViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}

// MARK: - SmallBannerContainerView

extension PreviewViewController: SmallBannerContainerView {
    
    func setSmallBannerHeight(_ height: CGFloat) {
        smallBannerContainerHeightConstraint.constant = height
    }
    
}
