//
//  BeaconMapCard.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation
import MapKit

struct BeaconMapCard: View {
    
    // MARK: Properties
    
    @State private var isFullScreenViewPresented = false
    @State private var isMapDetailViewPresented = false
    @State private var selectedAnnotation: IdentifiableAnnotation?
    
    private let style: MapStyle
    private let config: LocationDetailConfiguration
    
    // MARK: Initialization
    
    init(style: MapStyle) {
        self.style = style
        self.config = LocationDetailConfiguration(for: style)
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(alignment: .top, spacing: 12.0) {
                Button {
                    GDATelemetry.track("beacon_map_card.detail_view.selected", with: ["style": style.description])
                    
                    isMapDetailViewPresented = true
                } label: {
                    LocationDetailHeader(config: config)
                }
                .accessibilityHint(GDLocalizedString("beacon.action.view_details.acc_hint.details"))
                
                Spacer()
                
                Button {
                    GDATelemetry.track("beacon_map_card.full_screen.selected")
                    
                    isFullScreenViewPresented = true
                } label: {
                    Text(Image(systemName: "arrow.up.backward.and.arrow.down.forward"))
                        .roundedContrastText()
                }
                .accessibilityHidden(true)
            }
            
            Spacer()
        }
        .padding(12.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            MapView(style: style) { annotation in
                guard let annotation = annotation as? WaypointDetailAnnotation else {
                    // Currently, detail view is only supported for waypoint annotations
                    return
                }
                
                GDATelemetry.track("beacon_map_card.annotation.selected")
                
                selectedAnnotation = annotation.asIdentifiable
            }
        )
        .sheet(isPresented: $isFullScreenViewPresented) {
            BeaconMapView(style: style)
                .asModalNavigationView(isPresented: $isFullScreenViewPresented)
        }
        .sheet(isPresented: $isMapDetailViewPresented) {
            config.detailView
                .asModalNavigationView(isPresented: $isMapDetailViewPresented)
        }
        .sheet(item: $selectedAnnotation) { newValue in
            config.annotationDetailView(for: newValue.annotation)
                .asModalNavigationView {
                    // Dismiss
                    selectedAnnotation = nil
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tourWillEnd)) { _ in
            isFullScreenViewPresented = false
            isMapDetailViewPresented = false
            selectedAnnotation = nil
        }
    }
    
}

struct BeaconMapCard_Previews: PreviewProvider {
    
    static var content: AuthoredActivityContent {
        let availability = DateInterval(start: Date(), duration: 60 * 60 * 24 * 7)
        
        let waypoints = [
            ActivityWaypoint(coordinate: .init(latitude: 47.622111, longitude: -122.341000), name: "Important Place", description: "This is a waypoint in the activity", departureCallout: nil, arrivalCallout: nil, images: [], audioClips: [])
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
        VStack(spacing: 24.0) {
            BeaconMapCard(style: .tour(detail: behavior.content))
                .frame(height: 264.0)
                .cornerRadius(5.0)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 24.0)
        .background(Color.Theme.darkTeal.ignoresSafeArea())
        .environmentObject(UserLocationStore())
        
        VStack(spacing: 24.0) {
            BeaconMapCard(style: .waypoint(detail: WaypointDetail(index: 0, routeDetail: behavior.content)))
                .frame(height: 264.0)
                .cornerRadius(5.0)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 24.0)
        .background(Color.Theme.darkTeal.ignoresSafeArea())
        .environmentObject(UserLocationStore())
    }
    
}
