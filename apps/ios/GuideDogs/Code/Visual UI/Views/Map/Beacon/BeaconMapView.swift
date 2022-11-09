//
//  BeaconMapView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct BeaconMapView: View {
    
    // MARK: Properties
    
    @State private var isMapDetailViewPresented = false
    @State private var isAnnotationDetailViewPresented = false
    @State private var selectedAnnotation: IdentifiableAnnotation?
    
    private let style: MapStyle
    private let config: LocationDetailConfiguration
    
    // MARK: Initialization
    
    init(style: MapStyle) {
        self.style = style
        self.config = LocationDetailConfiguration(for: style)
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 12.0) {
                NavigationLink {
                    config.detailView
                } label: {
                    LocationDetailHeader(config: config)
                }
                .accessibilityHint(GDLocalizedString("beacon.action.view_details.acc_hint.details"))
                
                Spacer()
            }
            
            Spacer()
            
            NavigationLink(isActive: $isAnnotationDetailViewPresented) {
                config.annotationDetailView(for: selectedAnnotation?.annotation)
            } label: {
                EmptyView()
            }
            .accessibilityHidden(true)
        }
        .padding(12.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            MapView(style: style) { annotation in
                guard let annotation = annotation as? WaypointDetailAnnotation else {
                    // Currently, detail view is only supported for waypoint annotations
                    return
                }
                
                selectedAnnotation = annotation.asIdentifiable
                isAnnotationDetailViewPresented = true
            }
            .ignoresSafeArea()
        )
        .navigationTitle(config.title)
    }
}

struct BeaconMapView_Previews: PreviewProvider {
    
    static var content: AuthoredActivityContent {
        let availability = DateInterval(start: Date(), duration: 60 * 60 * 24 * 7)
        
        let waypoints = [
            ActivityWaypoint(coordinate: .init(latitude: 47.622111, longitude: -122.341000), name: "Important Place", description: "This is a waypoint in an activity", departureCallout: nil, arrivalCallout: nil, images: [], audioClips: [])
        ]
        
        return AuthoredActivityContent(id: UUID().uuidString,
                                       type: .orienteering,
                                       name: GDLocalizationUnnecessary("Paddlepalooza"),
                                       creator: GDLocalizationUnnecessary("Our Team"),
                                       locale: Locale.enUS,
                                       availability: availability,
                                       expires: false,
                                       image: nil,
                                       desc: GDLocalizationUnnecessary("This is a fun event! There will be a ton to do. You should come join us!"),
                                       waypoints: waypoints, pois: [])
    }
    
    static var behavior: GuidedTour {
        let detail = TourDetail(content: content)
        
        var state = TourState(id: detail.id)
        state.totalTime = 60 * 27 + 41
        state.visited.append(0)
        state.waypointIndex = 1
        
        let behavior = GuidedTour(detail, spatialData: AppContext.shared.spatialDataContext, motion: AppContext.shared.motionActivityContext)
        
        behavior.state = state
        
        return behavior
    }
    
    static var previews: some View {
        BeaconMapView(style: .tour(detail: behavior.content))
        BeaconMapView(style: .location(detail: behavior.content.waypoints.first!))
    }
    
}
