//
//  ExpandableLocationDetailMapViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit
import SwiftUI
import Combine

struct ExpandableMapView: UIViewControllerRepresentable {
    class Coordinator: EditableMapViewControllerDelegate {
        let defaultToEditMode: Bool
        
        private let updateHandler: ((LocationDetail, Bool) -> Void)?
        
        init(defaultToEditMode: Bool, _ handler: ((LocationDetail, Bool) -> Void)? = nil) {
            self.defaultToEditMode = defaultToEditMode
            updateHandler = handler
        }
        
        func viewController(_ viewController: UIViewController, didUpdateLocation locationDetail: LocationDetail, isAccessibilityEditing: Bool) {
            updateHandler?(locationDetail, isAccessibilityEditing)
        }
    }
    
    // MARK: Properties
    
    let style: MapStyle
    let isExpanded: Bool
    let isEditable: Bool
    let isMapsButtonHidden: Bool
    let isUserInteractionEnabled: Bool
    // `nil` if accessibility editing is not enabled
    let accessibilityEditableMapViewModel: AccessibilityEditableMapViewModel?
    
    private let updateHandler: ((LocationDetail, Bool) -> Void)?
    
    // MARK: Initialization
    
    init(style: MapStyle, isExpanded: Bool = false, isEditable: Bool = false, accessibilityEditableMapViewModel: AccessibilityEditableMapViewModel? = nil, isMapsButtonHidden: Bool = false, isUserInteractionEnabled: Bool = true, onLocationEditted: ((LocationDetail, Bool) -> Void)? = nil) {
        self.style = style
        self.isExpanded = isExpanded
        self.isEditable = isEditable
        self.isMapsButtonHidden = isMapsButtonHidden
        self.isUserInteractionEnabled = isUserInteractionEnabled
        self.updateHandler = onLocationEditted
        self.accessibilityEditableMapViewModel = accessibilityEditableMapViewModel
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(defaultToEditMode: isEditable, updateHandler)
    }
    
    // MARK: `UIViewControllerRepresentable`
    
    func makeUIViewController(context: Context) -> ExpandableMapViewController {
        let storyboard = UIStoryboard(name: "Map", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController() as! ExpandableMapViewController
        
        vc.isExpanded = isExpanded
        vc.isEditable = isEditable
        vc.isMapsButtonHidden = isMapsButtonHidden
        vc.isUserInteractionEnabled = isUserInteractionEnabled
        vc.style = style
        vc.delegate = context.coordinator
        vc.accessibilityEditableMapViewModel = accessibilityEditableMapViewModel
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ExpandableMapViewController, context: Context) {
        uiViewController.style = style
    }
}

class ExpandableMapViewController: UIViewController {
    
    // MARK: `IBOutlet`
    
    @IBOutlet private weak var accessibilityEditableMapView: UIView!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var mapsButton: UIButton!
    @IBOutlet private weak var fullScreenButton: UIButton!
    
    // MARK: Properties
    
    weak var delegate: EditableMapViewControllerDelegate?
    var isExpanded = false
    var isEditable = false
    var isMapsButtonHidden = false
    var isUserInteractionEnabled = true
    var accessibilityEditableMapViewModel: AccessibilityEditableMapViewModel?
    private var listeners: [AnyCancellable] = []
    
    var style: MapStyle? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            mapView.configure(for: style)
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.accessibilityIgnoresInvertColors = true
        
        mapView.configure(for: style)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.configure(for: style)
        
        // If Voiceover is running, hide accessibility elements for the map view
        // Do not hide these elements for other accessibility inputs, like the keyboard
        mapView.accessibilityElementsHidden = UIAccessibility.isVoiceOverRunning
        fullScreenButton.accessibilityElementsHidden = UIAccessibility.isVoiceOverRunning
        
        // If the map is editable, enable the editing with VO via the
        // `accessibilityEditButton`
        //
        // Currently, editing is not supported for waypoints
        // or routes
        if let accessibilityEditableMapViewModel = accessibilityEditableMapViewModel, case .location(let detail) = style {
            let content = AccessibilityEditableMapView(detail: detail) { [weak self] newValue in
                guard let `self` = self else {
                    return
                }
                
                self.delegate?.viewController(self, didUpdateLocation: newValue, isAccessibilityEditing: true)
            }
            .environmentObject(accessibilityEditableMapViewModel)
            
            let hostingController = UIHostingController(rootView: AnyView(content))
            hostingController.view.backgroundColor = .clear
            
            addChild(hostingController)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            accessibilityEditableMapView.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: accessibilityEditableMapView.leadingAnchor, constant: 0.0),
                hostingController.view.trailingAnchor.constraint(equalTo: accessibilityEditableMapView.trailingAnchor, constant: 0.0),
                hostingController.view.topAnchor.constraint(equalTo: accessibilityEditableMapView.topAnchor, constant: 0.0),
                hostingController.view.bottomAnchor.constraint(equalTo: accessibilityEditableMapView.bottomAnchor, constant: 0.0)
            ])

            hostingController.didMove(toParent: self)
            
            accessibilityEditableMapView.isHidden = !UIAccessibility.isVoiceOverRunning
        } else {
            accessibilityEditableMapView.isHidden = true
        }
        
        // Listen for changes in VO status and update the visibility of the edit location button
        // accordingly
        listeners.append(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
                            .receive(on: RunLoop.main)
                            .sink(receiveValue: { [weak self] _ in
                                guard let `self` = self else {
                                    return
                                }
                                
                                // If the map is editable, enable the editing with VO via the
                                // `accessibilityEditButton`
                                //
                                // Currently, editing is not supported for waypoints
                                // or routes
                                if self.accessibilityEditableMapViewModel != nil, case .location = self.style {
                                    self.accessibilityEditableMapView.isHidden = !UIAccessibility.isVoiceOverRunning
                                }
                                
                                self.mapView.accessibilityElementsHidden = UIAccessibility.isVoiceOverRunning
                                self.fullScreenButton.accessibilityElementsHidden = UIAccessibility.isVoiceOverRunning
                            }))
        
        if isExpanded {
            // If the map is already expanded, hide the full screen
            // button and use default iOS styling for the navigation bar
            fullScreenButton.isHidden = true
            navigationController?.navigationBar.configureAppearance(for: .default)
            
            if let style = style {
                // Set the title of the view
                switch style {
                case .location(let detail): title = detail.displayName
                case .waypoint(let detail): title = detail.displayName
                case .route(let detail): title = detail.displayName
                case .tour(let detail): title = detail.displayName
                }
            }
        } else {
            // If the map is is not expanded, show the full screen button
            fullScreenButton.isHidden = false
            
            // If the map view defaults to edit mode when expanded, then show the edit pencil icon instead of the expand icon
            if let delegate = delegate, delegate.defaultToEditMode {
                fullScreenButton.setImage(UIImage(systemName: "pencil"), for: .normal)
            }
        }
        
        // "Open in Maps" action is only enabled when viewing a single location
        // Additionally, the action can be disabled by a parent view
        if let style = style {
            switch style {
            case .location, .waypoint: mapsButton.isHidden = isMapsButtonHidden
            case .route, .tour: mapsButton.isHidden = true
            }
        } else {
            mapsButton.isHidden = true
        }
        
        // Ensure the tint color is not overwritten by a parent view
        mapView.tintColor = UIColor.systemBlue
        
        // Enable zoom, scroll, pane, etc.
        mapView.isUserInteractionEnabled = isUserInteractionEnabled
        
        // State of active route has changed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.routeGuidanceStateChanged).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard case .route = self.style else {
                return
            }
            
            // Route guidance is active - Update the map so that
            // it is centered on the new, current waypoint
            self.mapView.configure(for: self.style)
        })
        
        // State of active tour has changed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.tourStateChanged).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard case .tour = self.style else {
                return
            }
            
            // Tour guidance is active - Update the map so that
            // it is centered on the new, current waypoint
            self.mapView.configure(for: self.style)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        listeners.cancelAndRemoveAll()
    }
    
    // MARK: `IBAction`
    
    @IBAction func onLeftBarButtonItemSelected(_ sender: Any) {
        // `Cancel` selected
        // Dismiss view
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onDirectionsButtonTouchUpInside(_ sender: Any) {
        guard let style = style else {
            return
        }
        
        let locationDetail: LocationDetail?
        
        switch style {
        case .location(let detail): locationDetail = detail
        case .waypoint(let detail): locationDetail = detail.locationDetail
        // Directions are only enabled when viewing a single location
        case .route, .tour: locationDetail = nil
        }
        
        if let locationDetail = locationDetail {
            // Create and configure the alert controller.
            let alert = UIAlertController(title: GDLocalizedString("general.alert.choose_an_app"), message: nil, preferredStyle: .actionSheet)
            
            // TODO: Add actions to open the given location in a third-party map application
            // These applications must also be defined in 'Queried URL Schemes' in Info.plist
                    
            let cancelAction = UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction private func onFullScreenButtonTouchUpInside(_ sender: Any) {
        guard let style = style else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Map", bundle: Bundle.main)
        let navigationController: UINavigationController
        
        if isEditable {
            guard case .location(let detail) = style else {
                // Currently, editing is not supported for waypoints
                // or routes
                return
            }
            
            guard let nController = storyboard.instantiateViewController(identifier: "EditableMapNavigation") as? UINavigationController else {
                return
            }
            
            guard let vController = nController.viewControllers.first as? EditableMapViewController else {
                return
            }
            
            // Configure view controller
            vController.locationDetail = detail
            vController.delegate = self
            
            // Save view controllers
            navigationController = nController
        } else {
            guard let nController = storyboard.instantiateViewController(identifier: "ExpandableMapNavigation") as? UINavigationController else {
                return
            }
            
            guard let vController = nController.viewControllers.first as? ExpandableMapViewController else {
                return
            }
            
            // Configure view controller
            vController.style = style
            vController.isExpanded = true
            vController.isEditable = isEditable
            vController.isMapsButtonHidden = isMapsButtonHidden
            
            // Save view controllers
            navigationController = nController
        }
        
        // Present modally
        present(navigationController, animated: true, completion: nil)
    }
    
}

extension ExpandableMapViewController: EditableMapViewControllerDelegate {
    var defaultToEditMode: Bool {
        delegate?.defaultToEditMode ?? false
    }
    
    func viewController(_ viewController: UIViewController, didUpdateLocation locationDetail: LocationDetail, isAccessibilityEditing: Bool) {
        // The edit view should only be visible if the style was .location to start with, so just update that
        style = .location(detail: locationDetail)
        
        // Forward on the update
        delegate?.viewController(viewController, didUpdateLocation: locationDetail, isAccessibilityEditing: isAccessibilityEditing)
    }
}

extension ExpandableMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? LocationDetailAnnotation {
            return self.mapView(mapView, viewForLocationDetailAnnotation: annotation)
        }
        
        if let annotation = annotation as? WaypointDetailAnnotation {
            let canShowCallout: Bool
            
            switch style {
            case .route(let detail):
                // Disable the detail disclosure callout if the activity has expired
                canShowCallout = !detail.isExpiredTrailActivity
            case .tour:
                canShowCallout = true
            default:
                canShowCallout = false
            }
                
            return self.mapView(mapView, viewForWaypointDetailAnnotation: annotation, canShowCallout: canShowCallout)
        }
        
        if let annotation = annotation as? MKClusterAnnotation {
            return self.mapView(mapView, viewForClusterAnnotation: annotation)
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard let annotation = view.annotation as? WaypointDetailAnnotation else {
                return
            }
            
            let storyboard = UIStoryboard(name: "POITable", bundle: Bundle.main)
            
            guard let viewController = storyboard.instantiateViewController(identifier: "LocationDetailView") as? LocationDetailViewController else {
                return
            }
            
            viewController.waypointDetail = annotation.detail
            viewController.deleteAction = nil
            
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
}
