//
//  MKMapViewDelegate+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

extension MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewForLocationDetailAnnotation annotation: LocationDetailAnnotation) -> MKAnnotationView? {
        let identifier = LocationDetailAnnotationView.identifier
        var view: MKAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = LocationDetailAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, viewForWaypointDetailAnnotation annotation: WaypointDetailAnnotation, canShowCallout: Bool = false) -> MKAnnotationView? {
        var view: MKAnnotationView
        
        if canShowCallout {
            let identifier = CalloutWaypointDetailAnnotationView.identifier
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = CalloutWaypointDetailAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
        } else {
            let identifier = WaypointDetailAnnotationView.identifier
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = WaypointDetailAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, viewForClusterAnnotation annotation: MKClusterAnnotation) -> MKAnnotationView {
        let identifier = WaypointDetailClusterAnnotationView.identifier
        var view: MKAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = WaypointDetailClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        return view
    }

}
