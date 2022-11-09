//
//  NearbyTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import DZNEmptyDataSet
import CoreLocation
import Combine
import SwiftUI

class NearbyTableViewController: BaseTableViewController, POITableViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIView!
    
    weak var delegate: POITableViewDelegate?
    private var tableViewDataSource: UITableViewDataSource?
    private var tableViewDelegate: UITableViewDelegate?
    private var cellConfigurator = POITableViewCellConfigurator()
    var context: NearbyDataContext?
    private var data: NearbyData?
    private var subscriber: AnyCancellable?
    var onDismissPreviewHandler: (() -> Void)?
    
    var telemetryContext: String {
        if let usageLog = delegate?.usageLog, usageLog.isEmpty == false {
            return "\(usageLog).nearby_places"
        }
        
        return "nearby_places"
    }
    
    var currentFilter: NearbyTableFilter = NearbyTableFilter.defaultFilter {
        didSet {
            updateTableView()
        }
    }
    
    private var filteredPOIs: [POI] {
        guard let data = data else {
            return []
        }
        
        let maxLength = 50
        
        guard let location = context?.location else {
            let slice = data.pois.prefix(maxLength)
            return Array(slice)
        }
        
        let sortPredicate = Sort.distance(origin: location)
        var filterPredicate: FilterPredicate?
        
        // If a filter is selected, return the 50 closest
        // places of that selected type
        if let currentFilterType = currentFilter.type {
            filterPredicate = Filter.type(expected: currentFilterType)
        }
        
        return data.pois.sorted(by: sortPredicate, filteredBy: filterPredicate, maxLength: maxLength)
    }
    
    private var filterAlertController: UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("filter.alert_title"), message: nil, preferredStyle: .actionSheet)
        
        let filters = data?.filters ?? []
        
        for filter in filters {
            var title = filter.localizedString
            
            if filter == currentFilter {
                title = GDLocalizedString("filter.selected", filter.localizedString)
            }
            
            alertController.addAction(UIAlertAction(title: title, style: .default, handler: { (_) in
                GDATelemetry.track("nearby.filter.selected", with: ["filter": filter.type?.rawValue ?? "all", "context": self.delegate?.usageLog ?? ""])
                
                self.currentFilter = filter
            }))
        }
        
        alertController.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: nil))
        
        return alertController
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the back button
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        
        // Initialize `cellConfigurator` to display distances from the
        // user's current location
        cellConfigurator.location = context?.location
        // If `delegate` is set, then the delegate decides what happens when a location is selected
        // In this scenario, do not set accessibility actions
        cellConfigurator.accessibilityActionDelegate = delegate == nil ? self :  nil
        
        // Save initial value
        data = context?.data.value
        
        // Ensure `UITableViewDataSource` and `UITableViewDelegate` are always set
        updateTableView()
        
        // Set the DZNEmptyDataSet connections
        self.tableView.emptyDataSetSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.track("nearby_places.viewed", with: ["filter": currentFilter.type?.rawValue ?? "all", "context": delegate?.usageLog ?? ""])
        
        if let delegate = delegate, delegate.doneNavigationItem {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: GDLocalizedString("general.alert.done"), style: .done, target: self, action: #selector(self.onDone))
        }
        
        subscriber = context?.data
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .failure: break // If appropriate, show an alert
                case .finished: break // no-op
                }
            }, receiveValue: { [weak self] (newValue) in
                guard let `self` = self else {
                    return
                }
            
                // Save new value and present
                self.data = newValue
                self.updateTableView()
            })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        subscriber?.cancel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? LocationDetailViewController {
            let locationDetail = sender as? LocationDetail
            viewController.locationDetail = locationDetail
            viewController.deleteAction = .popToViewController(type: NearbyTableViewController.self)
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
    
    @objc
    private func onDone() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: `IBAction`
    
    @IBAction func unwindToNearby(segue: UIStoryboardSegue) {}
    
    // MARK: `UITableView`
    
    private func updateTableView() {
        DispatchQueue.main.async {
            let header = self.currentFilter.localizedString
            let action = self.currentFilter == NearbyTableFilter.defaultFilter ? FilterTableViewHeaderView.Action.set : FilterTableViewHeaderView.Action.clear
            
            // Save reference to `tableViewDataSource` and `tableViewDelegate`
            self.tableViewDataSource = TableViewDataSource(header: header, models: self.filteredPOIs, cellConfigurator: self.cellConfigurator)
            self.tableViewDelegate = GenericTableViewDelegate.make(selectDelegate: self, filterDelegate: self, filterAction: action)
        
            // Update `tableView` and reload
            self.tableView.dataSource = self.tableViewDataSource
            self.tableView.delegate = self.tableViewDelegate
            self.tableView.reloadData()
        }
    }
    
}

extension NearbyTableViewController: TableViewSelectDelegate {
    
    func didSelect(rowAtIndexPath indexPath: IndexPath) {
        GDATelemetry.track("poi_selected.nearby", with: ["filter": currentFilter.type?.rawValue ?? "all", "context": delegate?.usageLog ?? ""])
        
        guard let tableViewDataSource = tableViewDataSource as? TableViewDataSourceProtocol else {
            return
        }
        
        guard let poi: POI = tableViewDataSource.model(for: indexPath) else {
            return
        }
        
        self.didSelect(poi)
    }
    
    private func didSelect(_ entity: POI) {
        if let delegate = delegate {
            delegate.didSelect(poi: entity)
        } else {
            let detail = LocationDetail(entity: entity, telemetryContext: telemetryContext)
            performSegue(withIdentifier: "LocationDetailView", sender: detail)
        }
    }
    
    private func presentActivityIndicatorView() {
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
    
    private func dismissActivityIndicatorView() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.activityIndicatorView.removeFromSuperview()
        }
    }
    
}

extension NearbyTableViewController: FilterTableViewHeaderViewDelegate {
    
    var isEnabled: Bool {
        if let context = context, context.isLoading {
            // Enable filters while data is loading
            return true
        }
        
        guard let data = data else {
            return false
        }
        
        // If there are nearby places that can be filtered,
        // enable the filter button in the header view
        return data.pois.count > 0 && data.filters.count > 0
    }
    
    func didSelect(action: FilterTableViewHeaderView.Action) {
        switch action {
        case .clear: didClearFilter()
        case .set: didSetFilter()
        }
    }
    
    private func didClearFilter() {
        GDATelemetry.track("nearby.filter.cleared", with: ["filter": "all", "context": delegate?.usageLog ?? ""])
        
        currentFilter = NearbyTableFilter.defaultFilter
    }
    
    private func didSetFilter() {
        GDATelemetry.track("nearby.filter.set", with: ["context": delegate?.usageLog ?? ""])
        
        present(filterAlertController, animated: true, completion: nil)
    }
    
}

extension NearbyTableViewController: LocationAccessibilityActionDelegate {
    
    func didSelectLocationAction(_ action: LocationAction, entity: POI) {
        GDATelemetry.track(action.telemetryEvent, with: ["context": telemetryContext, "source": "accessibility_action"])
        
        let detail = LocationDetail(entity: entity, telemetryContext: self.telemetryContext)
        
        self.presentActivityIndicatorView()
        
        LocationDetail.fetchNameAndAddressIfNeeded(for: detail) { [weak self] (detail) in
            guard let `self` = self else {
                return
            }
            
            self.dismissActivityIndicatorView()
            
            self.didSelectLocationAction(action, detail: detail)
        }
    }
    
    private func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
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

extension NearbyTableViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let title: String
        
        if let context = context, context.isLoading {
            // Fetching nearby places
            title = GDLocalizedString("poi_screen.loading_title.loading")
        } else {
            title = GDLocalizedString("poi_screen.loading_title.no_places_matching", currentFilter.localizedString)
        }
        
        let color = Colors.Foreground.primary ?? .white
        let attributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1),
            NSAttributedString.Key.foregroundColor: color
        ]
        
        return NSAttributedString(string: title, attributes: attributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "ic__pin_drop_32px")
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            // If we are displaying a header in the empty table view and accessibility
            // font sizes are enabled, add a vertical offset
            return 44.0
        } else {
            return 0.0
        }
    }
    
}

extension NearbyTableViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
}

extension NearbyTableViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
