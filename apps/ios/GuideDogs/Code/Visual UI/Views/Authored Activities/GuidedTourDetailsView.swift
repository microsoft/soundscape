//
//  AuthoredActivityDetailsView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import SwiftUI
import CoreLocation

struct GuidedTourDetailsView: View {
    @EnvironmentObject var user: UserLocationStore
    @EnvironmentObject var navHelper: ViewNavigationHelper
    @ObservedObject var tourState: GuidedTourStateStore
    
    @State private var tour: TourDetail
    @State private var showingAlert = false
    @State private var indexWidth: CGFloat?
    @State private var isPresentingFirstUseShareAlert = false
    
    private var actions: [GuidedTourActionState] {
        return GuidedTourAction.actions(for: tour)
    }
    
    init(_ detail: TourDetail, designState: GuidedTourStateStore? = nil) {
        tour = detail
        tourState = designState ?? GuidedTourStateStore(detail.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(tour.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                
                if let description = tour.description, description.isEmpty == false {
                    Text(description)
                        .font(.body)
                        .padding()
                }
                
                // Create buttons for each action
                ForEach(actions, id: \.action) { actionState in
                    Button {
                        handleAction(actionState.action)
                    } label: {
                        RouteActionView(icon: actionState.icon, text: actionState.text)
                            .accessibility(hint: Text(actionState.accessibilityHint ?? ""))
                            .foregroundColor(actionState.isEnabled ? .primaryForeground : .gray)
                    }
                    .disabled(!actionState.isEnabled)
                }
                
                ExpandableMapView(style: .tour(detail: tour))
                    .frame(height: 160)
                
                ForEach(Array(tour.waypoints.enumerated()), id: \.0) { (index, waypoint) in
                    NavigationLink {
                        let detail = WaypointDetail(index: index, routeDetail: tour)
                        
                        WaypointDetailView(waypoint: detail, userLocation: user.location)
                    } label: {
                        WaypointCell(index: index,
                                     count: tour.waypoints.count,
                                     detail: waypoint,
                                     showAddress: waypoint.hasAddress,
                                     currentWaypointIndex: tourState.state?.waypointIndex,
                                     textWidth: indexWidth)
                            .multilineTextAlignment(.leading)
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                    }
                }
                .accessibilitySortPriority(0)
                
                Spacer()
            }
            .foregroundColor(.white)
            .assignPreference(for: MaxValue<WaypointCell.IndexWidth, CGFloat>.self, to: $indexWidth)
        }
        .background(Color.tertiaryBackground)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(GDLocalizedTextView("behavior.experiences.event_nav_title"))
        .alert(isPresented: $showingAlert, content: {
            Alert(title: GDLocalizedTextView("behavior.experiences.reset_and_update_action"),
                  message: GDLocalizedTextView("behavior.experiences.updates.prompt"),
                  primaryButton: .default(GDLocalizedTextView("general.alert.continue")) {
                self.checkForUpdates()
            },
                  secondaryButton: .cancel(GDLocalizedTextView("general.alert.cancel")))
        })
        .onAppear {
            GDATelemetry.trackScreenView("tour_details", with: ["isActivityActive": tour.isGuidanceActive.description])
        }
    }
}

extension GuidedTourDetailsView {
    private func handleAction(_ action: GuidedTourAction) {
        switch action {
        case .startTour:
            // Start the route immediately
            startTour(GuidedTour(tour,
                                 spatialData: AppContext.shared.spatialDataContext,
                                 motion: AppContext.shared.motionActivityContext))
            
        case .stopTour:
            stopTour()
            
        case .checkForUpdates:
            showingAlert = true
        }
    }
    
    private func startTour(_ tour: GuidedTour) {
        if AppContext.shared.eventProcessor.isCustomBehaviorActive {
            AppContext.shared.eventProcessor.deactivateCustom()
        }
        
        // Try to make VoiceOver focus on the beacon panel after we pop to the home view controller
        if let home = navHelper.host?.navigationController?.viewControllers.first as? HomeViewController {
            home.shouldFocusOnBeacon = true
        }
        
        AppContext.shared.eventProcessor.activateCustom(behavior: tour)
        navHelper.popToRootViewController(animated: true)
    }
    
    private func stopTour() {
        guard AppContext.shared.eventProcessor.isCustomBehaviorActive else {
            return
        }
        
        AppContext.shared.eventProcessor.deactivateCustom()
    }
    
    private func checkForUpdates(checkForUpdates: Bool = false) {
        let loader = AuthoredActivityLoader.shared
        loader.reset(tour.id)
        
        Task {
            guard let (_, content) = try await loader.updateData(tour.id) else {
                return
            }
            
            await MainActor.run {
                tour = TourDetail(content: content)
                
                UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("behavior.experiences.reset.confirmation"))
            }
        }
    }
}

struct GuidedTourDetailsView_Previews: PreviewProvider {
    static var testTourContent: AuthoredActivityContent {
        let availability = DateInterval(start: Date(), duration: 60 * 60 * 24 * 7)
        
        let waypoints = [
            ActivityWaypoint(coordinate: .init(latitude: 47.622111, longitude: -122.341000),
                             name: "Control 1",
                             description: "Near the large fountain at the entrance of the park"),
            ActivityWaypoint(coordinate: .init(latitude: 47.622031, longitude: -122.341100),
                             name: "Control 2",
                             description: "Up the large hill. Right at the top"),
            ActivityWaypoint(coordinate: .init(latitude: 47.621901, longitude: -122.341150),
                             name: "Control 3",
                             description: "Near the amphitheater at the far end of the park")
        ]
        
        return AuthoredActivityContent(id: UUID().uuidString,
                                       type: .guidedTour,
                                       name: GDLocalizationUnnecessary("Paddlepalooza"),
                                       creator: GDLocalizationUnnecessary("Our Team"),
                                       locale: Locale.enUS,
                                       availability: availability,
                                       expires: false,
                                       image: nil,
                                       desc: GDLocalizationUnnecessary("This is a fun event! There will be a ton to do. You should come join us!"),
                                       waypoints: waypoints, pois: [])
    }
    
    static var testTour: TourDetail {
        return TourDetail(content: testTourContent)
    }
    
    static var testTourState: GuidedTourStateStore {
        var state = TourState(id: testTourContent.id)
        state.totalTime = 60 * 27 + 41
        state.visited.append(0)
        state.waypointIndex = 1
        
        return GuidedTourStateStore(designData: testTourContent.id, state: state)
    }
    
    static var previews: some View {
        GuidedTourDetailsView(testTour, designState: testTourState)
            .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
            .previewDisplayName("Trail Activity")
            .previewLayout(.sizeThatFits)
        
        GuidedTourDetailsView(testTour, designState: testTourState)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
            .previewDisplayName("Trail Activity")
            .previewLayout(.sizeThatFits)
        
        NavigationView {
            GuidedTourDetailsView(testTour, designState: testTourState)
                .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
                .previewDisplayName("Trail Activity")
        }
    }
}
