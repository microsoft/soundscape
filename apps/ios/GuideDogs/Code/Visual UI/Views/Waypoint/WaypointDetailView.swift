//
//  WaypointDetailView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct WaypointDetailView: View {
    
    // MARK: Properties
    
    @State private var isNavigationLinkActive = false
    @State private var isShareAlertPresented = false
    
    let waypoint: WaypointDetail
    let userLocation: CLLocation?
    
    @ViewBuilder
    private var destination: some View {
        if let location = waypoint.locationDetail {
            let config = EditMarkerConfig(detail: location)
            EditMarkerView(config: config)
        } else {
            EmptyView()
        }
    }
    
    // MARK: `body`
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24.0) {
                if let location = waypoint.locationDetail {
                    LocationDetailLabelView(location: location, userLocation: userLocation)
                        .titleColor(.white)
                        .subtitleColor(Color.Theme.lightBlue)
                        .highlightColor(Color.Theme.yellow)
                    
                    VStack(spacing: 12.0) {
                        Divider()
                            .frame(height: 2.0)
                            .background(Color.black)
                        
                        if let audio = location.audio, !audio.isEmpty {
                            WaypointAudioView(activityID: waypoint.routeDetail.id, allAudio: audio)
                                .background(Color.Theme.blue)
                                .foregroundColor(.white)
                                .frame(height: audio.count > 1 ? 132.0 : 108.0)
                                .cornerRadius(5.0)
                        }
                        
                        WaypointImageCarousel(waypoint: waypoint)
                            .background(Color.Theme.blue)
                            .shadow(radius: 5.0)
                            .frame(height: 264.0)
                            .cornerRadius(5.0)
                    }
                }
                
                NavigationLink(
                    destination: destination,
                    isActive: $isNavigationLinkActive,
                    label: {
                        EmptyView()
                    })
                    .accessibilityHidden(true)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(24.0)
        .background(Color.tertiaryBackground.ignoresSafeArea())
        .navigationBarTitle(GDLocalizedString("location_detail.title.waypoint"))
        .onAppear {
            GDATelemetry.trackScreenView("waypoint_detail.tour", with: ["isActivityActive": waypoint.routeDetail.isGuidanceActive.description, "image_count": "\(waypoint.locationDetail?.images?.count ?? 0)", "audio_count": "\(waypoint.locationDetail?.audio?.count ?? 0)"])
        }
    }
    
    private func handle(action: LocationAction) {
        switch action {
        case .edit:
            GDATelemetry.track("waypoint_detail.action", with: ["action": "edit"])
            isNavigationLinkActive = true
        case .share(let isEnabled):
            guard isEnabled else {
                return
            }
            
            GDATelemetry.track("waypoint_detail.action", with: ["action": "share"])
            
            isShareAlertPresented = true
        default:
            // Action is not supported
            // no-op
            break
        }
    }
    
}

struct WaypointDetailView_Previews: PreviewProvider {
    
    static let userLocation = CLLocation(latitude: 47.640179, longitude: -122.111320)
    
    static let waypointLocation = CLLocation(latitude: 47.621901, longitude: -122.341150)
    
    static let images: [ActivityWaypointImage] = [
        ActivityWaypointImage(url: URL(string: "https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic")!, altText: "Description of photo")
    ]
    
    static let audio = [
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This audio belongs to a waypoint"),
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This is another audio clip for this waypoint."),
        ActivityWaypointAudioClip(url: Bundle.main.url(forResource: "calibration_success", withExtension: "wav")!, description: "This audio also belongs to a waypoint. This audio has a really really really really really really really really really really really really really really really really really really really long description so that I can test the multiline layout.")
    ]
    
    static let imported1 = ImportedLocationDetail(nickname: "Some Waypoint", annotation: "This is a description of the waypoint", images: nil, audio: audio)
    
    static let imported2 = ImportedLocationDetail(nickname: "Some Waypoint", annotation: "This is a description of the waypoint", images: images, audio: nil)
    
    static var route: RouteDetail {
        return RouteDetail(source: .database(id: ""), designData: .init(id: UUID().uuidString, name: "A Route", description: "A description", waypoints: [LocationDetail(location: waypointLocation, imported: imported1), LocationDetail(location: waypointLocation, imported: imported2)]))
    }
    
    static var previews: some View {
        WaypointDetailView(waypoint: WaypointDetail(index: 0, routeDetail: route), userLocation: userLocation)
        
        WaypointDetailView(waypoint: WaypointDetail(index: 1, routeDetail: route), userLocation: userLocation)
    }
    
}
