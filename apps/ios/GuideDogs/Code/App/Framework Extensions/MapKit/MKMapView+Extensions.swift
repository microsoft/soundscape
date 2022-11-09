//
//  MKMapView+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MapKit

extension MKMapView {
    
    func removeAllAnnotations() {
        guard annotations.count > 0 else {
            return
        }
        
        removeAnnotations(annotations)
    }
    
    private func showAnnotationAndCenter(_ annotation: MKAnnotation) {
        guard centerCoordinate != annotation.coordinate else {
            // no-op
            return
        }
        
        // Adjust the map region to display the given annotation
        showAnnotations([annotation], animated: true)
        centerCoordinate = annotation.coordinate
    }
    
    func configureEmptyMapView() {
        // If necessary, remove previous annotations
        removeAllAnnotations()
        
        // If there are no locations to display,
        // follow the user's location
        //
        // This is not an expected scenario
        userTrackingMode = .follow
    }
    
    func configure(for style: MapStyle?) {
        if let style = style {
            // If necessary, remove previous annotations
            removeAllAnnotations()
            
            // User tracking is enabled when displaying
            // an empty map
            // Turn off user tracking to display `MapStyle`
            userTrackingMode = .none
            
            switch style {
            case .location(let detail): configureMap(for: detail)
            case .waypoint(let detail): configureMap(for: detail)
            case .route(let detail): configureMap(for: detail)
            case .tour(let detail): configureMap(for: detail)
            }
        } else {
            configureEmptyMapView()
        }
    }
    
    private func configureMap(for detail: LocationDetail) {
        // Add an annotation at the given location
        let annotation = LocationDetailAnnotation(detail: detail)
        addAnnotation(annotation)
        
        // Adjust the map region to display the given annotation
        showAnnotationAndCenter(annotation)
    }
    
    private func configureMap(for detail: WaypointDetail) {
        if let annotation = WaypointDetailAnnotation(detail: detail) {
            // Add an annotation at the given location
            addAnnotation(annotation)
            
            // Adjust the map region to display the given annotation
            showAnnotationAndCenter(annotation)
        } else {
            // `annotation` should not be `nil`
            configureEmptyMapView()
        }
    }
    
    private func configureMap(for detail: RouteDetail) {
        configureMap(waypoints: detail.waypoints, currentIndex: detail.guidance?.currentWaypoint?.index, detail: detail)
    }
    
    private func configureMap(for detail: TourDetail) {
        configureMap(waypoints: detail.waypoints, currentIndex: detail.guidance?.currentWaypoint?.index, detail: detail)
    }
    
    private func configureMap(waypoints: [LocationDetail], currentIndex: Int?, detail: RouteDetailProtocol) {
        let annotations = waypoints.enumerated().compactMap { (index, _) -> WaypointDetailAnnotation? in
            // Add an annotation at the given location
            let detail = WaypointDetail(index: index, routeDetail: detail)
            return WaypointDetailAnnotation(detail: detail)
        }
        
        if annotations.isEmpty {
            // `annotations` should not be empty
            configureEmptyMapView()
        } else {
            // Add annotations at the given locations
            addAnnotations(annotations)
            
            if let currentIndex = currentIndex, let currentAnnotation = annotations.first(where: { $0.detail.index == currentIndex }) {
                // If the route is active, adjust the map region to display the current
                // waypoint
                showAnnotationAndCenter(currentAnnotation)
            } else if let firstAnnotation = annotations.first {
                // Adjust the map region to display the first waypoint
                showAnnotationAndCenter(firstAnnotation)
            }
        }
    }
    
}
