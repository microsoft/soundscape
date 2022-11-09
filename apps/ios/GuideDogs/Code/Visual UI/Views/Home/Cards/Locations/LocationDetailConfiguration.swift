//
//  LocationDetailConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import MapKit

struct LocationDetailConfiguration {
    
    private let style: MapStyle
    let isDetailViewEnabled: Bool
    
    init(for style: MapStyle, isDetailViewEnabled: Bool = true) {
        self.style = style
        self.isDetailViewEnabled = isDetailViewEnabled
    }
    
    // MARK: Configuration
    
    var title: String {
        switch style {
        case .location(let detail): return detail.displayName
        case .waypoint(let detail): return detail.displayName
        case .route(let detail): return detail.displayName
        case .tour(let detail): return detail.displayName
        }
    }
    
    var subtitle: String {
        switch style {
        case .location: return GDLocalizedString("beacon.audio_beacon")
        case .waypoint: return GDLocalizedString("waypoint.title")
        case .route: return GDLocalizedString("route_detail.beacon.title")
        case .tour: return GDLocalizedString("tour_detail.beacon.title")
        }
    }
    
    @ViewBuilder
    var detailView: some View {
        switch style {
        case .location, .route:
            // Unexpected State
            // Currently, detail view is only supported for waypoint / tour
            EmptyView()
        case .waypoint(let detail):
            WaypointDetailView(waypoint: detail, userLocation: AppContext.shared.geolocationManager.location)
        case .tour(let detail):
            GuidedTourDetailsView(detail)
                .environmentObject(UserLocationStore())
        }
    }
    
    @ViewBuilder
    func annotationDetailView(for annotation: MKAnnotation?) -> some View {
        if let annotation = annotation as? WaypointDetailAnnotation {
            WaypointDetailView(waypoint: annotation.detail, userLocation: AppContext.shared.geolocationManager.location)
        } else {
            // Unexpected state
            // Currently, detail view is only supported for waypoint annotations
            EmptyView()
        }
    }
    
}
