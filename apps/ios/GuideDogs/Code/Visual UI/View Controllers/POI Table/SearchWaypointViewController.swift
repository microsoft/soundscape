//
//  SearchWaypointViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

class SearchWaypointViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet var searchContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var waypointAddContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var waypointAddContainerView: UIView!
    
    var routeName: String?
    var waypoints: Binding<[IdentifiableLocationDetail]>?
    private var hostingController: UIViewController?
    private var searchController: UISearchController?
    
    private var cancellable: AnyCancellable?
    
    // MARK: View Life Cycle
    
    deinit {
        cancellable?.cancel()
        cancellable = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = GDLocalizedString("route_detail.edit.waypoints_button")
        
        // Initialize search controller
        self.searchController = UISearchController(delegate: self)
        
        // Add search controller to navigation bar
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        // Search results will be displayed modally
        // Use this view controller to define presentation context
        self.definesPresentationContext = true
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        
        updateWaypointAddList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: GDLocalizedString("general.alert.done"), style: .done, target: self, action: #selector(self.onDone))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cancellable?.cancel()
        cancellable = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        waypointAddContainerView.sizeToFit()
        
        let height = UIView.preferredContentHeightCompressedHeight(for: waypointAddContainerView)
        waypointAddContainerHeightConstraint.constant = height
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container is SearchTableViewController {
            searchContainerHeightConstraint.constant = container.preferredContentSize.height
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? SearchTableViewController {
            viewController.delegate = self
        }
    }
    
    @objc
    private func onDone() {
        dismiss(animated: true, completion: nil)
    }
    
    private func updateWaypointAddList() {
        if let hostingController = hostingController {
            hostingController.remove()
            self.hostingController = nil
        }
        
        if let waypoints = waypoints {
            let content = WaypointAddList(waypoints: waypoints)
            hostingController = UIHostingController(rootView: AnyView(content))
            
            guard let hostingController = hostingController else {
                return
            }
            
            addChild(hostingController)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            waypointAddContainerView.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: waypointAddContainerView.leadingAnchor, constant: 0.0),
                hostingController.view.trailingAnchor.constraint(equalTo: waypointAddContainerView.trailingAnchor, constant: 0.0),
                hostingController.view.topAnchor.constraint(equalTo: waypointAddContainerView.topAnchor, constant: 0.0),
                hostingController.view.bottomAnchor.constraint(equalTo: waypointAddContainerView.bottomAnchor, constant: 0.0)
            ])

            hostingController.didMove(toParent: self)
        }
    }
    
    private func addedMarker(id: String) {
        guard var waypoints = waypoints else {
            return
        }
        
        guard let detail = LocationDetail(markerId: id) else {
            return
        }
        
        guard waypoints.wrappedValue.contains(where: { $0.locationDetail.source == detail.source }) == false else {
            // Waypoint already exists
            return
        }
        
        // Add marker to waypoints
        let identifiable = IdentifiableLocationDetail(locationDetail: detail)
        waypoints.wrappedValue.append(identifiable)
        waypoints.update()
        
        updateWaypointAddList()
        
        // Reset search text
        searchController?.searchBar.searchTextField.text = nil
    }
    
    // MARK: `IBAction`
    
    @IBAction func unwindToSearchWaypoint(segue: UIStoryboardSegue) {
        // Reset search text
        searchController?.searchBar.searchTextField.text = nil
    }
}

// MARK: - POITableViewDelegate

extension SearchWaypointViewController: POITableViewDelegate {
    
    var poiAccessibilityHint: String {
        return GDLocalizedString("location_detail.add_waypoint.marker.hint")
    }
    
    var allowCurrentLocation: Bool {
        return true
    }
    
    var allowMarkers: Bool {
        return false
    }
    
    var usageLog: String {
        return "search_waypoint"
    }
    
    var doneNavigationItem: Bool {
        return true
    }
    
    private func didSelect(detail: LocationDetail) {
        if let markerId = detail.markerId {
            self.addedMarker(id: markerId)
            
            guard let navigationController = navigationController else {
                return
            }
            
            guard navigationController.topViewController != navigationController.viewControllers.first else {
                return
            }
            
            navigationController.popToRootViewController(animated: true)
        } else {
            let config = EditMarkerConfig(detail: detail,
                                          route: routeName,
                                          context: self.telemetryContext,
                                          addOrUpdateAction: .popToViewController(type: SearchWaypointViewController.self),
                                          deleteAction: nil,
                                          leftBarButtonItemIsHidden: false)
            
            if let vc = MarkerEditViewRepresentable(config: config).makeViewController() {
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            // Listen for a marker to be added
            cancellable = NotificationCenter.default.publisher(for: .markerAdded)
                .first()
                .compactMap({ $0.userInfo?[ReferenceEntity.Keys.entityId] as? String })
                .sink(receiveValue: { [weak self] markerId in
                    self?.addedMarker(id: markerId)
                })
        }
    }
    
    func didSelect(poi: POI) {
        didSelect(detail: LocationDetail(entity: poi))
    }
    
    func didSelect(currentLocation location: CLLocation) {
        didSelect(detail: LocationDetail(location: location))
    }
    
}

// MARK: - SearchResultsTableViewControllerDelegate

extension SearchWaypointViewController: SearchResultsTableViewControllerDelegate {
    
    func didSelectSearchResult(_ searchResult: POI) {
        didSelect(detail: LocationDetail(entity: searchResult))
    }
    
    var isCachingRequired: Bool {
        // Selected search results will be saved as a marker
        // Ensure that results can be cached (e.g., unencumbered coordinate is available)
        return true
    }
    
    var isAccessibilityActionsEnabled: Bool {
        // When a search result is selected, it will be saved as a marker
        // Disable custom accessibility actions (e.g., beacon, street preview, etc.)
        return false
    }
    
}

// MARK: - LocationActionDelegate

extension SearchWaypointViewController: LocationActionDelegate {
    
    var telemetryContext: String {
        return usageLog
    }
    
    func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail) {
        // no-op
        //
        // `SearchWaypointController` implements `POITableViewDelegate` instead of `LocationActionDelegate`
        // Code should be cleaned up in the future so that view controllers (or SwiftUI views) do not
        // need to implement both protocols to support the search and browse experience.
    }
    
}
