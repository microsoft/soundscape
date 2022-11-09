//
//  LocationDetailViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

class LocationDetailViewController: UIViewController {
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var detailTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var actionTableViewViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewContentView: UIView!
    
    // MARK: Properties
    
    private var detailViewController: LocationDetailTableViewController?
    private var actionViewController: LocationActionTableViewController?
    private var detailMapViewController: ExpandableMapViewController?
    
    var deleteAction: NavigationAction? = .popToRootViewController
    var onDismissPreviewHandler: (() -> Void)?
    
    private var cancellable: AnyCancellable?
    
    var locationDetail: LocationDetail? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            reloadView()
        }
    }
    
    var waypointDetail: WaypointDetail? {
        didSet {
            locationDetail = waypointDetail?.locationDetail
        }
    }
    
    var isInPreviewController: Bool {
        guard let vc = self.navigationController?.viewControllers.first else { return false }
        return vc is PreviewViewController
    }
    
    // MARK: View Life Cycle
    
    deinit {
        cancellable?.cancel()
        cancellable = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the back button
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        self.navigationController?.navigationBar.configureAppearance(for: .default)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let locationDetail = locationDetail else {
            GDATelemetry.trackScreenView("location_details")
            return
        }
        
        // Track the screen view
        var props: [String: String]?
        if let context = locationDetail.telemetryContext {
            props = ["context": context]
        }
        
        GDATelemetry.trackScreenView("location_details", with: props)
        
        if let markerId = locationDetail.markerId {
            cancellable = NotificationCenter.default.publisher(for: .markerUpdated).sink { notification in
                guard let id = notification.userInfo?[ReferenceEntity.Keys.entityId] as? String, id == markerId else {
                    return
                }
                
                guard let detail = LocationDetail(markerId: id) else {
                    return
                }
                
                self.locationDetail = detail
            }
        }
        
        // Show activity indicator
        activityIndicatorView.startAnimating()
        
        if locationDetail.isMarker {
            // Reload the table view in case the marker details have
            // been updated since the view last appeared
            reloadView()
            
            // Hide activity indicator
            activityIndicatorView.stopAnimating()
        } else {
            // If the location is not a marker, try to fetch an estimated name and
            // address, if necessary
            LocationDetail.fetchNameAndAddressIfNeeded(for: locationDetail) { [weak self] (newValue) in
                guard let `self` = self else {
                    return
                }
                
                self.locationDetail = newValue
                
                // Hide activity indicator
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? LocationDetailTableViewController {
            viewController.locationDetail = locationDetail
            detailViewController = viewController
        }
        
        if let viewController = segue.destination as? LocationActionTableViewController {
            viewController.locationDetail = locationDetail
            viewController.delegate = self
            actionViewController = viewController
        }
        
        if let viewController = segue.destination as? ExpandableMapViewController {
            if let detail = waypointDetail {
                viewController.style = .waypoint(detail: detail)
                viewController.isEditable = false
            } else if let detail = locationDetail {
                viewController.style = .location(detail: detail)
                viewController.isEditable = true
            }
            
            viewController.isExpanded = false
            viewController.delegate = self
            detailMapViewController = viewController
        }
        
        if let navigationController = segue.destination as? UINavigationController, let viewController = navigationController.topViewController as? PreviewViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
            viewController.onDismissHandler = { [weak self] in
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        if let viewController = segue.destination as? PreviewViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
            viewController.onDismissHandler = onDismissPreviewHandler
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container is LocationDetailTableViewController {
            detailTableViewHeightConstraint.constant = container.preferredContentSize.height
            // Update the height of the scroll view and redraw the map to fill the remaining space
            scrollViewHeightConstraint.constant = UIView.preferredContentHeight(for: scrollViewContentView)
        }
        
        if container is LocationActionTableViewController {
            actionTableViewViewHeightConstraint.constant = container.preferredContentSize.height
            // Update the height of the scroll view and redraw the map to fill the remaining space
            scrollViewHeightConstraint.constant = UIView.preferredContentHeight(for: scrollViewContentView)
        }
    }
    
    private func reloadView() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            // Update view title
            if self.waypointDetail != nil {
                self.title = GDLocalizedString("location_detail.title.waypoint")
            } else if let detail = self.locationDetail, detail.isMarker {
                self.title = GDLocalizedString("location_detail.title.marker")
            } else {
                self.title = GDLocalizedString("location_detail.title.default")
            }
            
            // Update child view controllers
            self.detailViewController?.locationDetail = self.locationDetail
            self.actionViewController?.locationDetail = self.locationDetail
            
            if let detail = self.waypointDetail {
                self.detailMapViewController?.style = .waypoint(detail: detail)
            } else if let detail = self.locationDetail {
                self.detailMapViewController?.style = .location(detail: detail)
            }
        }
    }
    
}

// MARK: - EditableMapViewControllerDelegate

extension LocationDetailViewController: EditableMapViewControllerDelegate {
    
    var defaultToEditMode: Bool {
        return false
    }
    
    func viewController(_ viewController: UIViewController, didUpdateLocation locationDetail: LocationDetail, isAccessibilityEditing: Bool) {
        if locationDetail.isMarker {
            self.locationDetail = locationDetail
        } else {
            // Show activity indicator
            activityIndicatorView.startAnimating()
            
            // If the location is not a marker, try to fetch an estimated name and
            // address, if necessary
            LocationDetail.fetchNameAndAddressIfNeeded(for: locationDetail) { [weak self] (newValue) in
                guard let `self` = self else {
                    return
                }
                
                self.locationDetail = newValue
                
                // Hide activity indicator
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
    
}

// MARK: - LocationActionDelegate

extension LocationDetailViewController: LocationActionDelegate {
    
    func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
        GDATelemetry.track(action.telemetryEvent, with: ["context": detail.telemetryContext ?? "", "source": "location_detail_view"])
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard action.isEnabled else {
                // Do nothing if the action is disabled
                return
            }
            
            do {
                switch action {
                case .save:
                    // Save the marker at the given location
                    let config = EditMarkerConfig(detail: detail,
                                                  route: nil,
                                                  context: detail.telemetryContext ?? "",
                                                  addOrUpdateAction: .popViewController,
                                                  deleteAction: nil,
                                                  leftBarButtonItemIsHidden: false) { [weak self] newValue in
                        self?.locationDetail = newValue
                    }
                    
                    if let vc = MarkerEditViewRepresentable(config: config).makeViewController() {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                case .edit:
                    // Edit the marker at the given location
                    let config = EditMarkerConfig(detail: detail,
                                                  route: nil,
                                                  context: detail.telemetryContext ?? "",
                                                  addOrUpdateAction: .popViewController,
                                                  deleteAction: self.deleteAction,
                                                  leftBarButtonItemIsHidden: false) { [weak self] newValue in
                        self?.locationDetail = newValue
                    }
                    
                    if let vc = MarkerEditViewRepresentable(config: config).makeViewController() {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                case .beacon:
                    // Set a beacon on the given location
                    // and segue to the home view
                    try LocationActionHandler.beacon(locationDetail: detail)
                    
                    if let home = self.navigationController?.viewControllers.first as? HomeViewController {
                        home.shouldFocusOnBeacon = true
                    }
                    
                    if self.isPresentedModally && !self.isInPreviewController {
                        self.dismiss(animated: true)
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                case .preview:
                    if AppContext.shared.isStreetPreviewing {
                        let alert = LocationActionAlert.restartPreview { [weak self] (_) in
                            self?.performSegue(withIdentifier: "UnwindPreviewView", sender: detail)
                        }
                        
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.performSegue(withIdentifier: "PreviewView", sender: detail)
                    }
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

// MARK: - LargeBannerContainerView

extension LocationDetailViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}
