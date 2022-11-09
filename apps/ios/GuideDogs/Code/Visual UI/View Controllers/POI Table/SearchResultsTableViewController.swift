//
//  SearchResultsTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import UIKit

protocol SearchResultsTableViewControllerDelegate: LocationActionDelegate {
    func didSelectSearchResult(_ searchResult: POI)
    var telemetryContext: String { get }
    // Set `isCachingRequired = true` if a selected search result will
    // be cached on device
    // Search results can only be cached when an unencumbered coordinate is available
    var isCachingRequired: Bool { get }
    // Set `isAccessibilityActionsEnabled = false` when search results should not include
    // custom accessibility actions (e.g., set beacon, save as marker, etc.)
    //
    // One example of when this will be false is the marker and beacon tutorials
    var isAccessibilityActionsEnabled: Bool { get }
}

class SearchResultsTableViewController: UITableViewController {
    
    typealias ListItem = ListItemTableViewCellConfigurator.ListItem
    
    enum ViewConfiguration {
        /// Represents a view that is embedded in another view, such as a search controller in another view controller.
        /// Default configuration. Used in the home view controller.
        case embedded
        /// Represents a standalone view, such as search controller that is presented modally.
        /// Used in the `search` user action.
        case standalone
    }
    
    private enum Results: String, StaticTableViewCell {
        case searching = "SearchingTableViewCell"
        case offline = "OfflineTableViewCell"
        
        var identifier: String {
            return self.rawValue
        }
    }
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var activityIndicatorView: UIView!
    
    // MARK: Properties
    
    var viewConfiguration = ViewConfiguration.embedded
    weak var delegate: SearchResultsTableViewControllerDelegate?
    let searchResultsUpdater = SearchResultsUpdater()
    private var tableViewDataSource: UITableViewDataSource?
    private var tableViewDelegate: UITableViewDelegate?
    private var currentVoiceoverAnnoucement: String?
    private(set) var isPresentingDefaultResults = false
    private var recentDataSource: UITableViewDataSource = TableViewDataSource<ListItem, ListItemTableViewCellConfigurator>(header: nil, models: [], cellConfigurator: ListItemTableViewCellConfigurator())
    private var recentDelegate: UITableViewDelegate = TableViewDelegate()
    private(set) var wasSearchCancelled = false
    
    private var searchController: UISearchController? {
        if isPresentedModally {
            return self.navigationItem.searchController
        } else {
            return self.parent as? UISearchController
        }
    }
    
    // MARK: Standalone configuration
    
    static func instantiateStandaloneConfiguration() -> NavigationController? {
        let storyboard = UIStoryboard(name: "POITable", bundle: nil)
        
        guard let searchVC = storyboard.instantiateViewController(withIdentifier: "SearchResultsTableView")
                as? SearchResultsTableViewController else { return nil }
        
        searchVC.viewConfiguration = .standalone
        
        let searchController = UISearchController(searchResultsController: searchVC, delegate: searchVC, displayInPlace: true)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.automaticallyShowsCancelButton = false
        
        searchVC.navigationItem.searchController = searchController
        searchVC.navigationItem.hidesSearchBarWhenScrolling = false
        
        let navigationVC = NavigationController(rootViewController: searchVC)
        return navigationVC
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if viewConfiguration == .standalone {
            self.title = GDLocalizedString("preview.search.label")
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: GDLocalizedString("general.alert.cancel"),
                                                                    style: .plain,
                                                                    target: self,
                                                                    action: #selector(dismissViewController))
        } else {
            self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.track("search.started", with: ["context": telemetryContext])
        
        // Reset wasSearchCancelled flag
        wasSearchCancelled = false
        
        let configurator = ListItemTableViewCellConfigurator()
        // Initialize `cellConfigurator` to display distances from the
        // user's current location
        configurator.location = AppContext.shared.geolocationManager.location
        // `delegate` should never be `nil`, but if it is, assume that actions are disabled
        let isAccessibilityActionsEnabled = delegate?.isAccessibilityActionsEnabled ?? false
        configurator.accessibilityActionDelegate = isAccessibilityActionsEnabled ? self :  nil
        
        // Initialize recent selections
        let selections = SpatialDataCache.recentlySelectedObjects()
        
        // Initialize recent callouts
        let callouts: [POI] = AppContext.shared.calloutHistory.callouts
            .sorted(by: { return $0.timestamp > $1.timestamp })
            .compactMap({
                var poi: POI?
            
                if let callout = $0 as? POICallout {
                    poi = callout.poi
                } else if let callout = $0 as? IntersectionCallout, let intersection = callout.intersection {
                    let latitude = intersection.location.coordinate.latitude
                    let longitude = intersection.location.coordinate.longitude
                    let name = GDLocalizedString("intersection.named_intersection", intersection.localizedName)
                    
                    poi = GenericLocation(lat: latitude, lon: longitude, name: name)
                } else if let callout = $0 as? WaypointArrivalCallout, let id = callout.waypoint.markerId, let marker = SpatialDataCache.referenceEntityByKey(id) {
                    poi = marker.getPOI()
                }
                
                return poi
            })
        
        let selectionDataSource = TableViewDataSource(header: nil, models: selections.asListItemWithoutIndex, cellConfigurator: configurator)
        let calloutDataSource = TableViewDataSource(header: GDLocalizedString("poi_screen.header.recent.callouts"), models: callouts.asListItemWithoutIndex, cellConfigurator: configurator)
        
        recentDataSource = SectionedTableViewDataSource(dataSources: [selectionDataSource, calloutDataSource])
        recentDelegate = GenericTableViewDelegate.make(selectDelegate: self)
        
        updateTableView(dataSource: recentDataSource, delegate: recentDelegate, voiceoverAnnoucement: nil, isDefaultResults: true)
        
        searchResultsUpdater.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        searchResultsUpdater.delegate = nil
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    // MARK: `UITableView`
    
    private func updateTableView(dataSource: UITableViewDataSource, delegate: UITableViewDelegate, voiceoverAnnoucement: String?, isDefaultResults: Bool) {
        DispatchQueue.main.async {
            // Cancel previous request to make a Voiceover annoucement
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.annouce(annoucement:)), object: self.currentVoiceoverAnnoucement)
            
            self.isPresentingDefaultResults = isDefaultResults
            
            // Reset `currentVoiceoverAnnoucement`
            self.currentVoiceoverAnnoucement = nil
            
            // Save reference to `tableViewDataSource` and `tableViewDelegate`
            self.tableViewDataSource = dataSource
            self.tableViewDelegate = delegate
            
            // Update `tableView` and reload
            self.tableView.dataSource = self.tableViewDataSource
            self.tableView.delegate = self.tableViewDelegate
            self.tableView.reloadData()
            
            self.updateNoResultsView()
            
            // If the search was cancelled, don't send any accessibility notifications...
            guard !self.wasSearchCancelled else {
                return
            }
            
            if let searchController = self.searchController, searchController.searchBar.searchTextField.isEditing == false {
                // When the keyboard is hidden, move Voiceover focus to `tableView`
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.tableView)
            }
            
            guard let voiceoverAnnoucement = voiceoverAnnoucement else {
                return
            }
            
            self.currentVoiceoverAnnoucement = voiceoverAnnoucement
            
            self.perform(#selector(self.annouce(annoucement:)), with: self.currentVoiceoverAnnoucement, afterDelay: 1.0)
        }
    }
    
    private func updateTableView(searchForMore: String?) {
        var models: [String] = []
        var annoucement = GDLocalizedString("search.no_results_found_with_hint")
        
        // Press the search button for more results
        // if it has not already been pressed
        if let searchForMore = searchForMore {
            models = [searchForMore]
            annoucement = GDLocalizedString("search.no_results_found_with_action")
        }
        
        let configurator = SearchTableViewCellConfigurator()
        let dataSource = TableViewDataSource(header: nil, models: models, cellConfigurator: configurator)
        let delegate = TableViewDelegate.make(selectDelegate: self)
        
        updateTableView(dataSource: dataSource, delegate: delegate, voiceoverAnnoucement: annoucement, isDefaultResults: false)
    }
    
    private func updateTableView(searchResults: [POI], searchLocation: CLLocation?) {
        if searchResults.isEmpty {
            updateTableView(dataSource: recentDataSource, delegate: recentDelegate, voiceoverAnnoucement: nil, isDefaultResults: true)
        } else {
            var dataSource: UITableViewDataSource
            let delegate = TableViewDelegate.make(selectDelegate: self)
            var annoucement: String?
            
            // Initialize `cellConfigurator` to display distances from the
            // search location
            let cellConfigurator = ListItemTableViewCellConfigurator()
            cellConfigurator.location = searchLocation
            // `delegate` should never be `nil`, but if it is, assume that actions are disabled
            let isAccessibilityActionsEnabled = self.delegate?.isAccessibilityActionsEnabled ?? false
            cellConfigurator.accessibilityActionDelegate = isAccessibilityActionsEnabled ? self :  nil
            
            dataSource = TableViewDataSource(header: nil, models: searchResults.asListItemWithIndex, cellConfigurator: cellConfigurator)
            
            if let first = searchResults.first {
                annoucement = GDLocalizedString("search.results_found_first_result", String(searchResults.count), first.localizedName)
            }
            
            updateTableView(dataSource: dataSource, delegate: delegate, voiceoverAnnoucement: annoucement, isDefaultResults: false)
        }
    }
    
    @objc
    private func annouce(annoucement: String?) {
        guard let annoucement = annoucement else {
            return
        }

        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: annoucement)
    }
    
    // MARK: Error Handling
    
    private func presentErrorAlert(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            // Failed to save selected entity
            let title = GDLocalizedString("universal_links.alert.error.title")
            let message = GDLocalizedString("location_detail.disabled.generic")
            let alert = ErrorAlerts.buildGeneric(title: title, message: message, dismissHandler: { [weak self] _ in
                self?.dismissActivityIndicator()
            })
            
            // Display error alert
            self?.present(alert, animated: true, completion: completion)
        }
    }
    
    // MARK: Activity Indicator
    
    private func presentActivityIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            // Show activity indicator
            self.view.addSubview(self.activityIndicatorView)
            // Update size and constraints
            self.activityIndicatorView.frame = self.view.bounds
            self.activityIndicatorView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.activityIndicatorView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            self.activityIndicatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            self.activityIndicatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        }
    }
    
    private func dismissActivityIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.activityIndicatorView.removeFromSuperview()
        }
    }
    
    // MARK: Helpers
    
    /// - Note: We are using the `tableHeaderView` for the empty state view instead of `DZNEmptyDataSet`.
    /// This is because when we show a footer, the `DZNEmptyDataSet` view and
    /// the footer display on top of each other.
    private func updateNoResultsView() {
        let show = self.tableView.visibleCells.isEmpty && !(searchController?.searchBar.searchTextField.isEditing ?? false)
        
        if show {
            self.tableView.tableHeaderView = SearchResultsTableViewController.noResultsLabel(with: self.view.bounds.width)
        } else {
            self.tableView.tableHeaderView = nil
        }
    }
    
    /// Used as the `tableHeaderView` when there are no results
    private static func noResultsLabel(with width: CGFloat) -> UILabel {
        // Create string
        let attributedText = NSMutableAttributedString()
        
        let color = Colors.Foreground.primary ?? UIColor.white
        let title = NSAttributedString(string: GDLocalizedString("searching.no_results_found_title"),
                                       attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1),
                                                    NSAttributedString.Key.foregroundColor: color])
        attributedText.append(title)
        
        attributedText.append(NSAttributedString(string: "\n"))
        
        let description = NSAttributedString(string: GDLocalizedString("searching.no_results_found_message"),
                                             attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body),
                                                          NSAttributedString.Key.foregroundColor: color])
        attributedText.append(description)
        
        // Calculate label size
        let constraintSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingRect = attributedText.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, context: nil)
        let height = ceil(boundingRect.height)
        
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
            .inset(by: UIEdgeInsets(top: -20, left: 0, bottom: -20, right: 0))
        
        // Create label
        let label = UILabel(frame: frame)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.attributedText = attributedText
        
        return label
    }
    
}

// MARK: - SearchResultsUpdaterDelegate

extension SearchResultsTableViewController: SearchResultsUpdaterDelegate {
    
    func searchResultsDidStartUpdating() {
        let dataSource: UITableViewDataSource
        let delegate = TableViewDelegate.make(selectDelegate: self)
        let voiceoverAnnoucement: String?
        
        if AppContext.shared.offlineContext.state == .online {
            // We are waiting for results to be returned
            dataSource = StaticTableViewDataSource(header: nil, cells: [Results.searching])
            voiceoverAnnoucement = nil
        } else {
            // Search is disabled while offline
            dataSource = StaticTableViewDataSource(header: nil, cells: [Results.offline])
            voiceoverAnnoucement = GDLocalizedString("searching.offline")
        }
        
        updateTableView(dataSource: dataSource, delegate: delegate, voiceoverAnnoucement: voiceoverAnnoucement, isDefaultResults: false)
    }
    
    func searchResultsDidUpdate(_ searchResults: [POI], searchLocation: CLLocation?) {
        updateTableView(searchResults: searchResults, searchLocation: searchLocation)
    }
    
    func searchResultsDidUpdate(_ searchForMore: String?) {
        updateTableView(searchForMore: searchForMore)
    }
    
    func searchWasCancelled() {
        wasSearchCancelled = true
    }
    
    var telemetryContext: String {
        guard delegate !== self else {
            return ""
        }
        
        return delegate?.telemetryContext ?? ""
    }
    
    var isCachingRequired: Bool {
        // `delegate` should never be `nil`, but if it is, assume that caching
        // is required
        guard delegate !== self else {
            return true
        }
        
        return delegate?.isCachingRequired ?? true
    }
    
}

// MARK: - TableViewSelectDelegate

extension SearchResultsTableViewController: TableViewSelectDelegate {
    
    func didSelect(rowAtIndexPath indexPath: IndexPath) {
        guard let tableViewDataSource = tableViewDataSource as? TableViewDataSourceProtocol else {
            return
        }
        
        if let searchString: String = tableViewDataSource.model(for: indexPath) {
            GDATelemetry.track("search_for_more_selected.search", with: ["context": telemetryContext])
            
            didSelectSearchStringResult(searchString)
        } else if let poi: POI = tableViewDataSource.model(for: indexPath) {
            didSelectEntityResult(poi)
        } else if let listItem: ListItem = tableViewDataSource.model(for: indexPath) {
            didSelectEntityResult(listItem.item)
        }
    }
    
    private func didSelectEntityResult(_ poi: POI) {
        // Display activity indicator
        presentActivityIndicator()
        
        // Fetch entity data
        searchResultsUpdater.selectSearchResult(poi) { [weak self] (result, error) in
            guard let `self` = self else {
                return
            }
            
            self.dismissActivityIndicator()
            
            if error == nil {
                switch result {
                case .entity(let value): self.dismissOnDidSelectSearchResult(value)
                case .suggestion(let value): self.didSelectSearchStringResult(value)
                case .none: self.presentErrorAlert()
                }
            } else {
                self.presentErrorAlert()
            }
        }
    }
    
    private func didSelectSearchStringResult(_ searchString: String) {
        // Stop editing and remove current search results
        searchController?.searchBar.searchTextField.endEditing(false)
        
        // Indicate that the new search text is complete
        searchResultsUpdater.context = .completeSearchText
        
        // Update search bar text
        searchController?.searchBar.text = searchString
        
        // Reset context
        searchResultsUpdater.context = .partialSearchText
    }
    
    private func dismissOnDidSelectSearchResult(_ entity: POI) {
        // If the selected result will be cached on device but caching is not enabled
        // (e.g., unencumbered coordinate is not available), present the error alert
        // and return
        if isCachingRequired {
            let detail = LocationDetail(entity: entity)
            
            guard detail.source.isCachingEnabled else {
                self.presentErrorAlert()
                return
            }
        }
        
        let completion = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if self.isPresentingDefaultResults == false {
                // If the user has selected a result from a search, update
                // the last selected date for that result
                let detail = LocationDetail(entity: entity)
                detail.updateLastSelectedDate()
            }
            
            self.delegate?.didSelectSearchResult(entity)
        }
        
        if viewConfiguration == .embedded {
            self.dismiss(animated: true) {
                completion()
            }
        } else {
            completion()
        }
    }
    
}

// MARK: - LocationAccessibilityActionDelegate

extension SearchResultsTableViewController: LocationAccessibilityActionDelegate {
    
    func didSelectLocationAction(_ action: LocationAction, entity: POI) {
        // Display activity indicator
        presentActivityIndicator()
        
        // Fetch entity data
        searchResultsUpdater.selectSearchResult(entity) { [weak self] (result, error) in
            guard let `self` = self else {
                return
            }
            
            if let result = result, error == nil {
                switch result {
                case .entity(let value):
                    var context = "search_results"
                    
                    if let telemetryContext = self.delegate?.telemetryContext, telemetryContext.isEmpty == false {
                        context = "\(telemetryContext).search_results"
                    }
                    
                    let detail = LocationDetail(entity: value, telemetryContext: context)
                    
                    LocationDetail.fetchNameAndAddressIfNeeded(for: detail) { [weak self] (newValue) in
                        guard let `self` = self else {
                            return
                        }
                        
                        self.dismissActivityIndicator()
                        
                        self.dismiss(animated: true) { [weak self] in
                            guard let `self` = self else {
                                return
                            }
                            
                            self.delegate?.didSelectLocationAction(action, detail: newValue)
                        }
                    }
                default:
                    // Actions are only available for entity results
                    // and should not be available for search suggestions
                    self.presentErrorAlert()
                }
            } else {
                self.presentErrorAlert()
            }
        }
    }
    
}

// MARK: - SearchResultsTableViewControllerDelegate

/// The methods and properties in this delegate will only be used when the `viewConfiguration` is `standalone`
extension SearchResultsTableViewController: SearchResultsTableViewControllerDelegate {
    
    /// Invoked when selecting a search result via a custom VoiceOver action
    func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
        // no-op
    }
    
    /// Invoked when selecting a search result via tap
    func didSelectSearchResult(_ searchResult: POI) {
        let storyboard = UIStoryboard(name: "POITable", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "LocationDetailView") as? LocationDetailViewController else { return }
        viewController.locationDetail = LocationDetail(entity: searchResult, telemetryContext: "search_result")
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    var isAccessibilityActionsEnabled: Bool {
        return true
    }
    
}

// MARK: -

private extension Array where Element == POI {
    
    typealias ListItem = ListItemTableViewCellConfigurator.ListItem
    
    var asListItemWithIndex: [ListItem] {
        let count = self.count
        
        return enumerated().compactMap { (index, item) in
            return ListItem(item: item, index: index + 1, count: count)
        }
    }
    
    var asListItemWithoutIndex: [ListItem] {
        return compactMap({ return ListItem(item: $0) })
    }
    
}
