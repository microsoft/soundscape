//
//  HomeViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreMotion
import CoreLocation
import MessageUI
import CocoaLumberjackSwift
import SwiftUI
import Combine

extension Notification.Name {
    static let homeViewControllerDidLoad = Notification.Name("HomeViewControllerDidLoad")
}

class HomeViewController: UIViewController {
    
    // MARK: Segues
    
    struct Segue {
        
        // Main Menu Segues
        
        static let showRecreationActivities = "ShowRecreationActivities"
        static let showManageDevices = "ShowManageDevices"
        static let showStatus = "ShowStatus"
        static let showHelp = "ShowHelpSegue"
        static let showSettings = "ShowSettingsSegue"
        
        /// This method returns the segue associated with items in the main menu.
        ///
        /// - Parameter menuItem: A menu item
        /// - Returns: The segue associated with this menu item
        static func segue(for menuItem: MenuItem) -> String? {
            switch menuItem {
            case .recreation: return Segue.showRecreationActivities
            case .devices:    return Segue.showManageDevices
            case .help:       return Segue.showHelp
            case .settings:   return Segue.showSettings
            case .status:     return Segue.showStatus
            default:          return nil
            }
        }
    }
    
    // MARK: Properties
    
    // Banners
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var smallBannerContainerView: UIView!
    @IBOutlet weak var smallBannerContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sleepIcon: UIImageView!
    @IBOutlet weak var sleepButton: UIButton!
    
    @IBOutlet var searchContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var cardContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var calloutPanelContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var cardContainerTopConstraints: [NSLayoutConstraint]!
    
    private var previousSearchContainerHeight = 0.0
    
    fileprivate var lastLocation: CLLocation?
    
    // New feature view
    
    fileprivate var didCheckForNewFeatures = false
    
    var shouldFocusOnBeacon: Bool = false
    
    lazy var externalGPSBarButtonItem: UIBarButtonItem = {
        let icon = UIBarButtonItem(image: UIImage(named: "ic_settings_input_antenna_white"),
                               style: .plain,
                               target: nil,
                               action: nil)
        icon.accessibilityLabel = GDLocalizedString("bar_icon.external_GPS.acc_label")
        return icon
    }()
    
    private var searchController: UISearchController?
    
    // Experiences
    
    var cardViewController: CardStateViewController?
    var experienceDidStartObserver: NSObjectProtocol?
    var experienceDidFailToDownloadObserver: NSObjectProtocol?
    var listeners: [AnyCancellable] = []
    
    // Callout Button Panel
    
    private weak var calloutButtonViewController: CalloutButtonPanelViewController?
    
    // MARK: View Life Cycle
    
    deinit {
        if let token = experienceDidStartObserver {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let token = experienceDidFailToDownloadObserver {
            NotificationCenter.default.removeObserver(token)
        }
        
        listeners.cancelAndRemoveAll()
        
        DDLogDebug("\(String(describing: type(of: self))) deinitialized")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the search controller
        self.searchController = UISearchController(delegate: self)
        self.searchController?.delegate = self
        self.searchController?.searchBar.searchTextField.accessibilityIdentifier = GDLocalizationUnnecessary("searchbar.home")
        
        // Add search controller to navigation bar
        configureSearchAndBrowseView()
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        // Search results will be displayed modally
        // Use this view controller to define presentation context
        self.definesPresentationContext = true
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        
        // Subscribe to notifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLocationUpdatedNotification), name: Notification.Name.locationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.continueUserAction), name: Notification.Name.continueUserAction, object: nil)
        
        AppContext.shared.remoteCommandManager.delegate = self
        
        experienceDidStartObserver = NotificationCenter.default.addObserver(forName: Notification.Name.processedActivityDeepLink, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            self?.showOrRefreshExperiences()
        })
        
        experienceDidFailToDownloadObserver = NotificationCenter.default.addObserver(forName: Notification.Name.activityDownloadDidFail, object: nil, queue: OperationQueue.main, using: { [weak self] (_) in
            let alert = UIAlertController(title: GDLocalizedString("behavior.experiences.download_failed.title"),
                                          message: GDLocalizedString("behavior.experiences.download_failed.error"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorActivated).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] _ in
            self?.configureSearchAndBrowseView()
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorDeactivated).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] _ in
            self?.configureSearchAndBrowseView()
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .didTryActivityUpdate).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard let userInfo = notification.userInfo else {
                return
            }
            
            guard let updatesAvailable = userInfo[AuthoredActivityLoader.Keys.updateAvailable] as? Bool else {
                return
            }
            
            guard let success = userInfo[AuthoredActivityLoader.Keys.updateSuccess] as? Bool else {
                return
            }
            
            let alert: UIAlertController
            
            if success {
                alert = UIAlertController.activityDidUpdate()
            } else if !updatesAvailable {
                alert = UIAlertController.activityUpdateUnavailable()
            } else {
                alert = UIAlertController.activityDidFailToUpdate()
            }
            
            self.present(alert, animated: true)
        }))
        
        NotificationCenter.default.post(name: Notification.Name.homeViewControllerDidLoad, object: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("home")
        
        updateCalloutButtonTraits()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        // Transparent navigation bar
        navigationController?.navigationBar.configureAppearance(for: .transparentLightTitle)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAppWillEnterForeground(_:)), name: Notification.Name.appWillEnterForeground, object: nil)
        
        guard checkPermissions() else {
            // Prevents edge case of New Feature Feature displaying after fixing location services
            // permissions on first launch (caused because iOS kills the app if you change the Motion
            // & Fitness setting in the Settings app).
            if AppContext.shared.isFirstLaunch {
                SettingsContext.shared.newFeaturesLastDisplayedVersion = AppContext.appVersion
                didCheckForNewFeatures = true
            }
            
            return
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldFocusOnBeacon, UIAccessibility.isVoiceOverRunning, let vc = cardViewController?.currentVC as? BeaconViewHostingController {
            GDLogAppInfo("Focusing VoiceOver on the beacon UI")
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: vc.view)
            shouldFocusOnBeacon = false
        }
        
        guard !didCheckForNewFeatures else {
            return
        }
        
        if AppContext.shared.newFeatures.shouldShowNewFeatures() {
            let vc = NewFeaturesViewController(nibName: "NewFeaturesView", bundle: nil)
            
            vc.newFeatures = AppContext.shared.newFeatures
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            vc.accessibilityViewIsModal = true
            
            self.present(vc, animated: !UIAccessibility.isVoiceOverRunning, completion: nil)
        } else {
            // Attempt activities (e.g., user survey, share & rate app) that may be scheduled on app launch
            // Coordinator ensures that only one activity is attempted when the view appears
            LaunchActivityCoordinator.coordinateActivitiesOnAppLaunch(from: self)
        }
        
        didCheckForNewFeatures = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Default navigation bar
        navigationController?.navigationBar.configureAppearance(for: .default)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.appWillEnterForeground, object: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateCalloutButtonTraits()
        configureSearchAndBrowseView()
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
        
        if container is SearchTableViewController {
            searchContainerHeightConstraint.constant = container.preferredContentSize.height
            // Save value
            previousSearchContainerHeight = container.preferredContentSize.height
        }
        
        if container is CalloutButtonPanelViewController {
            calloutPanelContainerHeightConstraint.constant = container.preferredContentSize.height
        }
        
        if container is CardStateViewController {
            cardContainerHeightConstraint.constant = container.preferredContentSize.height
        }
    }
    
    private func configureSearchAndBrowseView() {
        if AppContext.shared.eventProcessor.activeBehavior is GuidedTour {
            navigationItem.searchController = nil
            searchContainerHeightConstraint.constant = 0.0
            NSLayoutConstraint.deactivate(cardContainerTopConstraints)
        } else {
            navigationItem.searchController = self.searchController
            searchContainerHeightConstraint.constant = previousSearchContainerHeight
            NSLayoutConstraint.activate(cardContainerTopConstraints)
        }
    }
    
    private func showOrRefreshExperiences() {
        if navigationController?.visibleViewController is HomeViewController {
            
            // The HomeViewController is currently the visible VC - segue to the AuthoredActivitiesList
            performSegue(withIdentifier: Segue.showRecreationActivities, sender: self)
            
        } else if let vc = navigationController?.visibleViewController as? MenuViewController {
            
            // The MenuViewController is currently the visible VC - dismiss it and segue to the AdaptiveSportsEventsList
            vc.dismiss(animated: true) { [weak self] in
                self?.performSegue(withIdentifier: Segue.showRecreationActivities, sender: self)
            }
            
        } else {
            
            // Some other view controller is currently the visible VC - return to home and then segue to the AuthoredActivitiesList
            CATransaction.begin()
            navigationController?.popToViewController(self, animated: true)
            CATransaction.setCompletionBlock { [weak self] in
                self?.performSegue(withIdentifier: Segue.showRecreationActivities, sender: self)
            }
            CATransaction.commit()
            
        }
    }
    
    @discardableResult
    func checkPermissions() -> Bool {
        let geolocationManager = AppContext.shared.geolocationManager
        
        if !geolocationManager.coreLocationServicesEnabled {
            self.performSegue(withIdentifier: "EnableLocationServices", sender: nil)
            return false
        }
        
        switch geolocationManager.coreLocationAuthorizationStatus {
        case .notDetermined:
            self.performSegue(withIdentifier: "RequestLocationServices", sender: nil)
            return false
        case .reducedAccuracyLocationAuthorized, .denied:
            self.performSegue(withIdentifier: "AuthorizeLocationServices", sender: nil)
            return false
        default:
            // Authorized
            break
        }
        
        MotionActivityContext.requestAuthorization { [unowned self] (authorized, _) in
            if !authorized && !UIDeviceManager.isSimulator {
                // While Motion & Fitness is not authorized, disable callouts
                if SettingsContext.shared.automaticCalloutsEnabled {
                    MotionActivityContext.motionFitnessDidToggleCallouts = true
                    AppContext.process(ToggleAutoCalloutsEvent(playSound: false))
                }
                
                // Use additional context regarding authorization so we can distinguish between Fitness Tracking
                // being turned off on the device and Motion & Fitness being disabled for the app
                let motionAuth = CMMotionActivityManager.authorizationStatus()
                
                if motionAuth == .notDetermined {
                    self.performSegue(withIdentifier: "RequestMotionFitness", sender: nil)
                    return
                }
                
                if motionAuth == .denied {
                    self.performSegue(withIdentifier: "AuthorizeMotionFitness", sender: nil)
                    return
                }
                
                if motionAuth == .restricted {
                    self.performSegue(withIdentifier: "EnableMotionFitness", sender: nil)
                    return
                }
                
                // We cannot distinguish between Fitness Tracking being turned off on the
                // device and Motion & Fitness being disabled for the app
                self.performSegue(withIdentifier: "AuthorizeMotionFitness", sender: nil)
                return
            } else {
                // If necessary, turn callouts back on
                if MotionActivityContext.motionFitnessDidToggleCallouts {
                    MotionActivityContext.motionFitnessDidToggleCallouts = false
                    AppContext.process(ToggleAutoCalloutsEvent(playSound: false))
                }
            }
        }
        
        return true
    }
    
    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? LocationPermissionViewController {
            vc.displayAsModal = true
        } else if let vc = segue.destination as? MotionPermissionViewController {
            vc.displayAsModal = true
        } else if let vc = segue.destination as? DestinationTutorialIntroViewController {
            vc.source = self
            vc.logContext = telemetryContext
        } else if let vc = segue.destination as? MarkerTutorialViewController {
            vc.logContext = telemetryContext
        } else if let vc = segue.destination as? StandbyViewController {
            vc.delegate = self
        } else if let vc = segue.destination as? LoadingModalViewController {
            vc.loadingMessage = GDLocalizedString("general.loading.almost_ready")
        } else if let vc = segue.destination as? LocationDetailViewController {
            let locationDetail = sender as? LocationDetail
            vc.locationDetail = locationDetail
        } else if let vc = segue.destination as? CardStateViewController {
            cardViewController = vc
        } else if let vc = segue.destination as? CalloutButtonPanelViewController {
            calloutButtonViewController = vc
            calloutButtonViewController?.logContext = telemetryContext
        } else if let navigationController = segue.destination as? UINavigationController,
                  let viewController = navigationController.topViewController as? PreviewViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
        }
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        if segue.source is DestinationTutorialViewController {
            FirstUseExperience.setDidComplete(for: .beaconTutorial)
        }
        
        if segue.source is DestinationTutorialIntroViewController {
            // The user skipped the demo, so prevent it from showing again
            FirstUseExperience.setDidComplete(for: .beaconTutorial)
        }
        
        // Transparent navigation bar
        navigationController?.navigationBar.configureAppearance(for: .transparentLightTitle)
    }
}

// MARK: UIViewControllerTransitioningDelegate

// This delegate is only used for animating the home screen menu in and off of the screen. This is not used for any of the other segues in the app.
extension HomeViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard presented is MenuViewController else {
            return nil
        }
        
        return MenuAnimator(.open)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let dismissed = dismissed as? MenuViewController else {
            return nil
        }
        
        return MenuAnimator(.close) { [weak self] (finished) in
            guard finished, let segue = Segue.segue(for: dismissed.selected) else {
                return
            }
            
            self?.performSegue(withIdentifier: segue, sender: self)
        }
    }
}

// MARK: Actions

extension HomeViewController {
    
    @IBAction func onMenuTouchUpInside() {
        // Construct the menu and present it
        let vc = MenuViewController()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .custom
        
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func onSleepTouchUpInside () {
        performSegue(withIdentifier: "showStandbyScreen", sender: nil)
        
        return
    }

}

// MARK: Notifications

extension HomeViewController {
    
    @objc func handleAppWillEnterForeground(_ notification: Notification) {
        checkPermissions()
    }
    
    @objc func handleLocationUpdatedNotification(_ notification: Notification) {
        guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
            return
        }
        
        lastLocation = location
    }
    
    @objc private func continueUserAction(_ notification: Notification) {
        guard !AppContext.shared.isStreetPreviewing else {
            // `PreviewViewController` will handle the user action
            return
        }
        
        guard let userAction = notification.userInfo?[UserActionManager.Keys.userAction] as? UserAction else { return }
        
        GDLogAppInfo("Continuing user action: \(userAction.rawValue)")
        
        switch userAction {
        case .myLocation:
            calloutButtonViewController?.handleDidToggleLocateNotification(notification)
        case .aroundMe:
            calloutButtonViewController?.handleDidToggleOrientateNotification(notification)
        case .aheadOfMe:
            calloutButtonViewController?.handleDidToggleLookAheadNotification(notification)
        case .nearbyMarkers:
            calloutButtonViewController?.handleDidToggleMarkedPointsNotification(notification)
        case .search, .saveMarker, .streetPreview:
            break
        }
    }
    
}

// MARK: Update View Methods

extension HomeViewController {
    
    fileprivate func updateExternalHardwareGeolocationIndicatorView(isExternal: Bool) {
        // Show the external hardware indicator if needed
        if isExternal {
            // Check if the indicator is already showing
            if var rightBarButtonItems = navigationItem.rightBarButtonItems {
                    if rightBarButtonItems.contains(externalGPSBarButtonItem) {
                        return
                    } else {
                        // We add the indicator to the current bar button items
                        rightBarButtonItems.append(externalGPSBarButtonItem)
                        DispatchQueue.main.async { [weak self] in
                            self?.navigationItem.rightBarButtonItems = rightBarButtonItems
                        }
                }
            } else {
                // No other current bar button items. show only the indicator.
                DispatchQueue.main.async { [weak self] in
                    self?.navigationItem.rightBarButtonItem = self?.externalGPSBarButtonItem
                }
            }
        } else {
            // Hide the external hardware indicator if needed
            self.navigationItem.remove(barButtonItem: externalGPSBarButtonItem)
        }
        
        var barButtonItems: [UIBarButtonItem] = []
        
        if isExternal {
            barButtonItems.append(externalGPSBarButtonItem)
        }
        
        navigationItem.rightBarButtonItems = barButtonItems
    }
    
}

// MARK: - DismissableViewControllerDelegate

extension HomeViewController: DismissableViewControllerDelegate {
    
    func onDismissed(_ viewController: UIViewController) {
        // If there is an active route guidance behavior, then unmute the audio beacon
        if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance,
           !AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled {
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
        }
    }
    
}

// MARK: - SearchResultsTableViewControllerDelegate

extension HomeViewController: SearchResultsTableViewControllerDelegate {
    
    func didSelectSearchResult(_ searchResult: POI) {
        let detail = LocationDetail(entity: searchResult, telemetryContext: "search_result")
        performSegue(withIdentifier: "LocationDetailView", sender: detail)
        
        searchController?.isActive = false
    }
    
    var isCachingRequired: Bool {
        // After a result is selected, we will navigate to the detail view for that location
        // The detail view will disable any actions that require caching
        return false
    }
    
    var isAccessibilityActionsEnabled: Bool {
        return true
    }
    
    var telemetryContext: String {
        return "home_screen"
    }
}

// MARK: - LocationActionDelegate

extension HomeViewController: LocationActionDelegate {
    
    func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard action.isEnabled else {
                // Do nothing if the action is disabled
                return
            }
            
            self.searchController?.isActive = false
            
            do {
                switch action {
                case .save, .edit:
                    // Edit the marker at the given location
                    // Segue to the edit marker view
                    let config = EditMarkerConfig(detail: detail,
                                                  route: nil,
                                                  context: self.telemetryContext,
                                                  addOrUpdateAction: .popToRootViewController,
                                                  deleteAction: .popToRootViewController,
                                                  leftBarButtonItemIsHidden: false)
                    
                    if let vc = MarkerEditViewRepresentable(config: config).makeViewController() {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                case .beacon:
                    // Set a beacon on the given location
                    // and segue to the home view
                    try LocationActionHandler.beacon(locationDetail: detail)
                    self.navigationController?.popToRootViewController(animated: true)
                case .preview:
                    self.performSegue(withIdentifier: "PreviewView", sender: detail)
                case .share:
                    // Create a URL to share a marker at the given location
                    let url = try LocationActionHandler.share(locationDetail: detail)
                    // Present the activity view controller
                    let alert = ShareMarkerAlert.shareMarker(url, markerName: detail.displayName)
                    
                    if FirstUseExperience.didComplete(.share) {
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let firstUseAlert = ShareMarkerAlert.firstUseExperience(dismissHandler: { [weak self] _ in
                            guard let `self` = self else {
                                return
                            }
                            
                            FirstUseExperience.setDidComplete(for: .share)
                            
                            self.present(alert, animated: true, completion: nil)
                        })
                        
                        self.present(firstUseAlert, animated: true, completion: nil)
                    }
                }
            } catch let error as LocationActionError {
                let alert = LocationActionAlert.alert(for: error)
                self.present(alert, animated: true, completion: nil)
            } catch {
                let alert = LocationActionAlert.alert(for: error)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}

// MARK: - UISearchControllerDelegate

extension HomeViewController: UISearchControllerDelegate {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        // Default navigation bar
        navigationController?.navigationBar.configureAppearance(for: .default)
        
        NSUserActivity(userAction: .search).becomeCurrent()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        // Transparent navigation bar
        navigationController?.navigationBar.configureAppearance(for: .transparentLightTitle)
    }
    
}

// MARK: - LargeBannerContainerView

extension HomeViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}

// MARK: - SmallBannerContainerView

extension HomeViewController: SmallBannerContainerView {
    
    func setSmallBannerHeight(_ height: CGFloat) {
        smallBannerContainerHeightConstraint.constant = height
    }
    
}

private extension UIAlertController {
    
    static func activityDidUpdate() -> UIAlertController {
        let alert = UIAlertController(title: GDLocalizedString("route.update.success.title"), message: GDLocalizedString("route.update.success.message"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .default))
        return alert
    }
    
    static func activityDidFailToUpdate() -> UIAlertController {
        let alert = UIAlertController(title: GDLocalizedString("route.update.fail.title"), message: GDLocalizedString("route.update.fail.message"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .default))
        return alert
    }
    
    static func activityUpdateUnavailable() -> UIAlertController {
        let alert = UIAlertController(title: GDLocalizedString("route.update.unavailable.title"), message: GDLocalizedString("route.update.unavailable.message"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .default))
        return alert
    }
    
}
