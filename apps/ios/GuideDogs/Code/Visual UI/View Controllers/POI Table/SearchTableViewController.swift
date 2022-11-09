//
//  SearchTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import CoreLocation

/// Very simple subclass of `StaticTableViewDataSource` that allows for adding some
/// custom accessibility actions to cells in the table.
private class SearchTableDataSource: StaticTableViewDataSource {
    private let currentLocationActions: [UIAccessibilityCustomAction]
    var showCurrentLocationActivityIndicator: Bool = false
    
    init(header: String?, cells: [StaticTableViewCell], currentLocationActions: [UIAccessibilityCustomAction]) {
        self.currentLocationActions = currentLocationActions
        
        super.init(header: header, cells: cells)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        // Add accessibility action to the "Current Location" cell
        if cells[indexPath.row].identifier == SearchTableViewController.MoreLocations.currentLocation.rawValue {
            cell.accessibilityCustomActions = currentLocationActions
            
            if showCurrentLocationActivityIndicator, let activityCell = cell as? CustomDisclosureTableViewCell {
                activityCell.showActivityIndicator()
            }
        }
        
        return cell
    }
}

class SearchTableViewController: BaseTableViewController {
    
    fileprivate enum MoreLocations: String, StaticTableViewCell {
        case markers = "MarkersTableViewCell"
        case currentLocation = "CurrentLocationTableViewCell"
        case nearby = "ExploreNearbyTableViewCell"
        
        var identifier: String {
            return self.rawValue
        }
    }
    
    // MARK: Properties
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    
    weak var delegate: POITableViewDelegate?
    private var tableViewDataSource: UITableViewDataSource?
    private var tableViewDelegate: UITableViewDelegate?
    private var searchController: UISearchController?
    var onDismissPreviewHandler: (() -> Void)?
    // If no delegate is provided, `logContext` allows for setting the context for the screen_view telemetry log
    var logContext: String = ""
    
    private lazy var moreLocations: [MoreLocations] = {
        var rows: [MoreLocations] = [
            MoreLocations.nearby
        ]
        
        if delegate?.allowMarkers ?? true {
            rows.append(MoreLocations.markers)
        }
        
        if delegate?.allowCurrentLocation ?? true && AppContext.shared.isStreetPreviewing == false {
            rows.append(MoreLocations.currentLocation)
        }
        
        return rows
    }()
    
    private var saveCurrentLocationAction: UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: LocationAction.save(isEnabled: true).text) { [weak self] _ -> Bool in
            DispatchQueue.main.async { [weak self] in
                self?.saveCurrentLocation()
            }
            
            return true
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If this is a release build, hide `Nearby Places Map`
        if FeatureFlag.isEnabled(.developerTools) == false {
            navigationItem.rightBarButtonItems = []
        }
        
        // Initialize search controller
        self.searchController = UISearchController(delegate: self)
        
        // Add search controller to navigation bar
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        // Search results will be displayed modally
        // Use this view controller to define presentation context
        self.definesPresentationContext = true
        
        updateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView(title ?? "Select a Location", with: ["context": delegate?.usageLog ?? logContext])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchController?.isActive = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? POITableViewController {
            viewController.delegate = self.delegate
            viewController.onDismissPreviewHandler = onDismissPreviewHandler
        }
        
        if let viewController = segue.destination as? LocationDetailViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
            viewController.onDismissPreviewHandler = onDismissPreviewHandler
        }
        
        if let viewController = segue.destination as? MarkersAndRoutesListHostViewController {
            viewController.onDismissPreviewHandler = onDismissPreviewHandler
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        preferredContentSize.height = UIView.preferredContentHeight(for: tableView)
    }
    
    // `UITableView`
    
    private func updateTableView() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            // Save reference to `tableViewDataSource` and `tableViewDelegate`
            if self.parent is HomeViewController {
                // Only support custom action on "Current Location" from the HomeViewController
                self.tableViewDataSource = SearchTableDataSource(header: nil, cells: self.moreLocations, currentLocationActions: [self.saveCurrentLocationAction])
            } else {
                self.tableViewDataSource = StaticTableViewDataSource(header: nil, cells: self.moreLocations)
            }
            
            self.tableViewDelegate = GenericTableViewDelegate.make(selectDelegate: self)
        
            // Update `tableView` and reload
            self.tableView.dataSource = self.tableViewDataSource
            self.tableView.delegate = self.tableViewDelegate
            self.tableView.reloadData()
        }
    }
    
    /// Private method used by a custom accessibility action that allows for jumping straight to saving
    /// the current location as a marker without loading the Location Details screen
    private func saveCurrentLocation() {
        guard let location = AppContext.shared.geolocationManager.location else {
            self.present(ErrorAlerts.buildLocationAlert(), animated: true, completion: nil)
            return
        }
        
        if let dataSource = tableViewDataSource as? SearchTableDataSource {
            dataSource.showCurrentLocationActivityIndicator = true
            tableView.reloadData()
        }
        
        let detail = LocationDetail(location: location, telemetryContext: "current_location")
        
        // If the location is not a marker, try to fetch an estimated name and
        // address, if necessary
        LocationDetail.fetchNameAndAddressIfNeeded(for: detail) { [weak self] (newValue) in
            self?.didSelectLocationAction(.save(isEnabled: true), detail: newValue)
        }
    }
    
}

extension SearchTableViewController: SearchResultsTableViewControllerDelegate {
    
    func didSelectSearchResult(_ searchResult: POI) {
        if let delegate = delegate {
            delegate.didSelect(poi: searchResult)
        } else {
            let detail = LocationDetail(entity: searchResult, telemetryContext: "search_result")
            performSegue(withIdentifier: "LocationDetailView", sender: detail)
        }
    }
    
    var telemetryContext: String {
        return delegate?.usageLog ?? ""
    }
    
    var isCachingRequired: Bool {
        if let delegate = delegate {
            return delegate.isCachingRequired
        } else {
            // After a result is selected, we will navigate to the detail view for that location
            // The detail view will disable any actions that require caching
            return true
        }
    }
    
    var isAccessibilityActionsEnabled: Bool {
        // If there is no delegate, we will navigate to the detail view for a selected location
        // In this scenario, enable custom accessibility actions
        return delegate == nil
    }
    
}

extension SearchTableViewController: TableViewSelectDelegate {
    
    func didSelect(rowAtIndexPath indexPath: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if self.tableView.cellForRow(at: indexPath)?.reuseIdentifier == MoreLocations.currentLocation.identifier {
                GDATelemetry.track("poi_selected.current_location", with: ["context": self.delegate?.usageLog ?? ""])
                
                // Selected current location cell
                guard let location = AppContext.shared.geolocationManager.location else {
                    self.present(ErrorAlerts.buildLocationAlert(), animated: true, completion: nil)
                    return
                }
                
                // Dismiss `UISearchResultsController`
                self.searchController?.isActive = false
                
                if let delegate = self.delegate {
                    delegate.didSelect(currentLocation: location)
                } else {
                    let detail = LocationDetail(location: location, telemetryContext: "current_location")
                    self.performSegue(withIdentifier: "LocationDetailView", sender: detail)
                }
            }
        }
    }
    
}

extension SearchTableViewController: LocationActionDelegate {
    
    func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
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
                case .save, .edit:
                    // Hide activity indicator if necessary
                    if let dataSource = self.tableViewDataSource as? SearchTableDataSource,
                       dataSource.showCurrentLocationActivityIndicator == true {
                        dataSource.showCurrentLocationActivityIndicator = false
                        self.tableView.reloadData()
                    }
                    
                    // Edit the marker at the given location
                    // Segue to the edit marker view
                    let config = EditMarkerConfig(detail: detail,
                                                  route: nil,
                                                  context: self.telemetryContext,
                                                  addOrUpdateAction: .popViewController,
                                                  deleteAction: .popViewController,
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

extension SearchTableViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
