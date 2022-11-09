//
//  MapViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit
import Combine

protocol MapViewControllerDelegate: AnyObject {
    func didSelectAnnotation(_ annotation: MKAnnotation)
}

class MapViewController: UIViewController {
    
    // MARK: `IBOutlet`
    
    @IBOutlet private weak var mapView: MKMapView!
    
    // MARK: Properties
    
    weak var delegate: MapViewControllerDelegate?
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
        
        // Hide accessibility elements for the map view
        mapView.accessibilityElementsHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.configure(for: style)
        
        // Ensure the tint color is not overwritten by a parent view
        mapView.tintColor = UIColor.systemBlue
        
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
    
}

extension MapViewController: MKMapViewDelegate {
    
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
            
            guard let annotation = view.annotation else {
                return
            }
            
            self.delegate?.didSelectAnnotation(annotation)
        }
    }
    
}
