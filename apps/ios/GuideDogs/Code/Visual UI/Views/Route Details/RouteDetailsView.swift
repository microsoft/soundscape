//
//  RouteDetailsView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct RouteActionView: View {
    @ScaledMetric(relativeTo: .body) private var actionBtnSize: CGFloat = 20.0
    
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: actionBtnSize)
                .padding([.trailing], 16)
                .accessibilityHidden(true)
            
            Text(text)
                .font(.body)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding()
    }
}

struct RouteDetailsView: View {
    enum ActionType {
        case reset, update
    }
    
    enum NavigationDestination {
        case tutorial, edit
    }
    
    @EnvironmentObject var user: UserLocationStore
    @EnvironmentObject var navHelper: ViewNavigationHelper
    @ObservedObject var routeState: RouteGuidanceStateStore
    @StateObject var route: RouteStore
    
    @State private var navDestination: NavigationDestination?
    @State private var goToNavDestination: Bool = false
    @State private var showingSheet = false
    @State private var activeSheet: ActionType = .reset
    @State private var indexWidth: CGFloat?
    @State private var isPresentingFirstUseShareAlert = false
    
    let isTrailActivity: Bool
    let deleteAction: NavigationAction?
    
    /// Temporary solution for the fact that the map control currently only accepts a
    /// single LocationDetail as input. When it is extended to display multiple items,
    /// we can update the reference below and replace this property
    private var mapLocationDetail: LocationDetail {
        return LocationDetail(location: route.detail.waypoints[0].location,
                              imported: nil,
                              telemetryContext: nil)
    }
    
    private var actions: [RouteActionState] {
        return RouteAction.actions(for: route.detail)
    }
    
    init(_ detail: RouteDetail, deleteAction action: NavigationAction?, designState: RouteGuidanceStateStore? = nil) {
        _route = .init(wrappedValue: RouteStore(detail))
        routeState = designState ?? RouteGuidanceStateStore(detail.id)
        deleteAction = action
        
        switch detail.source {
        case .trailActivity:
            isTrailActivity = true
        default:
            isTrailActivity = false
        }
    }
    
    var actionSheet: ActionSheet {
        switch activeSheet {
        case .reset:
            return ActionSheet(
                title: Text(GDLocalizedString("behavior.experiences.reset.title")),
                message: Text(GDLocalizedString("behavior.experiences.reset.prompt")),
                buttons: [
                    .destructive(Text(GDLocalizedString("behavior.experiences.reset_action"))) {
                        self.resetActivity()
                    },
                    .destructive(Text(GDLocalizedString("behavior.experiences.reset_and_update_action"))) {
                        self.resetActivity(checkForUpdates: true)
                    },
                    .cancel(Text(GDLocalizedString("general.alert.cancel")))
                ]
            )
            
        case .update:
            return ActionSheet(
                title: GDLocalizedTextView("behavior.experiences.more_actions"),
                message: GDLocalizedTextView("behavior.experiences.updates.prompt"),
                buttons: [
                    .destructive(Text(GDLocalizedString("behavior.experiences.reset_and_update_action"))) {
                        self.resetActivity(checkForUpdates: true)
                    },
                    .cancel(Text(GDLocalizedString("general.alert.cancel")))
                ])
        }
    }
    
    @ViewBuilder var destinationView: some View {
        switch navDestination {
        case .edit:
            RouteEditView(style: .edit(detail: route.detail), deleteAction: deleteAction)
                .environmentObject(navHelper as ViewNavigationHelper)
            
        case .tutorial:
            RouteTutorialView(detail: route.detail, isShown: $goToNavDestination)
                .navigationBarHidden(true)
                .environmentObject(navHelper)
            
        case .none:
            EmptyView()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(route.detail.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                }
                .padding()
                
                if let description = route.detail.description, description.isEmpty == false {
                    Text(description)
                        .font(.body)
                        .padding()
                }
                
                // Create buttons for each action
                ForEach(actions, id: \.action) { actionState in
                    Button {
                        handleRouteAction(actionState.action)
                    } label: {
                        RouteActionView(icon: actionState.icon, text: actionState.text)
                            .accessibility(hint: Text(actionState.accessibilityHint ?? ""))
                            .foregroundColor(actionState.isEnabled ? .primaryForeground : .gray)
                    }
                    .disabled(!actionState.isEnabled)
                }
                
                ExpandableMapView(style: .route(detail: route.detail))
                    .frame(height: 160)
                
                ForEach(Array(route.detail.waypoints.enumerated()), id: \.0) { (index, waypoint) in
                    WaypointCell(index: index,
                                 count: route.detail.waypoints.count,
                                 detail: waypoint,
                                 showAddress: !isTrailActivity,
                                 currentWaypointIndex: routeState.state?.waypointIndex,
                                 textWidth: indexWidth)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                        .onTapGesture {
                            DispatchQueue.main.async {
                                // Block users from loading waypoint details if the activity is expired
                                guard !route.detail.isExpiredTrailActivity else {
                                    return
                                }
                                
                                let storyboard = UIStoryboard(name: "POITable", bundle: Bundle.main)
                                
                                guard let viewController = storyboard.instantiateViewController(identifier: "LocationDetailView") as? LocationDetailViewController else {
                                    return
                                }
                                
                                viewController.waypointDetail = WaypointDetail(index: index, routeDetail: route.detail)
                                
                                navHelper.pushViewController(viewController, animated: true)
                            }
                        }
                }
                .accessibilitySortPriority(0)
                
                NavigationLink(destination: destinationView, isActive: $goToNavDestination) {
                    EmptyView()
                }
                .accessibilityHidden(true)
                
                Spacer()
            }
            .foregroundColor(.white)
            .assignPreference(for: MaxValue<WaypointCell.IndexWidth, CGFloat>.self, to: $indexWidth)
        }
        .background(Color.tertiaryBackground)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(isTrailActivity ? GDLocalizedTextView("behavior.experiences.event_nav_title") : GDLocalizedTextView("behavior.experiences.route_nav_title"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isTrailActivity {
                    Button(action: {
                        activeSheet = .update
                        showingSheet = true
                    }, label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primaryForeground)
                    })
                    .accessibilityHint(GDLocalizedTextView("behavior.experiences.more_actions"))
                }
            }
        }
        .actionSheet(isPresented: $showingSheet) { actionSheet }
        .onAppear {
            GDATelemetry.trackScreenView("route_details")
        }
        .alert(isPresented: $isPresentingFirstUseShareAlert, content: {
            return SoundscapeDocumentAlert.firstUseExperience {
                FirstUseExperience.setDidComplete(for: .share)
                
                presentShareActivityViewController()
            }
        })
    }
}

extension RouteDetailsView {
    private func handleRouteAction(_ action: RouteAction) {
        switch action {
        case .startRoute, .startTrailActivity:
            if case .database = route.detail.source, !FirstUseExperience.didComplete(.routeTutorial) {
                // Show the tutorial
                navDestination = .tutorial
                goToNavDestination = true
            } else {
                // Start the route immediately
                startGuidance(RouteGuidance(route.detail,
                                            spatialData: AppContext.shared.spatialDataContext,
                                            motion: AppContext.shared.motionActivityContext))
            }
            
        case .stopRoute, .stopTrailActivity:
            stopGuidance()
            
        case .resetTrailActivity:
            activeSheet = .reset
            showingSheet = true
            
        case .share:
            GDATelemetry.track("routes.share", with: ["source": "route_detail_view"])
            
            if FirstUseExperience.didComplete(.share) {
                presentShareActivityViewController()
            } else {
                isPresentingFirstUseShareAlert = true
            }
            
        case .edit:
            navDestination = .edit
            goToNavDestination = true
        }
    }
    
    private func startGuidance(_ guidance: RouteGuidance) {
        if AppContext.shared.eventProcessor.isCustomBehaviorActive {
            AppContext.shared.eventProcessor.deactivateCustom()
        }
        
        // Try to make VoiceOver focus on the beacon panel after we pop to the home view controller
        if let home = navHelper.host?.navigationController?.viewControllers.first as? HomeViewController {
            home.shouldFocusOnBeacon = true
        }
        
        AppContext.shared.eventProcessor.activateCustom(behavior: guidance)
        navHelper.popToRootViewController(animated: true)
    }
    
    private func stopGuidance() {
        guard AppContext.shared.eventProcessor.isCustomBehaviorActive else {
            return
        }
        
        AppContext.shared.eventProcessor.deactivateCustom()
    }
    
    private func resetActivity(checkForUpdates: Bool = false) {
        let loader = AuthoredActivityLoader.shared
        
        guard case .trailActivity(let content) = route.detail.source else {
            return
        }
        
        loader.reset(content.id)
        
        guard checkForUpdates else {
            UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("behavior.experiences.reset.confirmation"))
            return
        }
        
        Task {
            guard let (_, content) = try await loader.updateData(content.id) else {
                return
            }
            
            await MainActor.run {
                route.update(RouteDetail(source: .trailActivity(content: content)))
                UIAccessibility.post(notification: .announcement,
                                     argument: GDLocalizedString("behavior.experiences.reset.confirmation"))
            }
        }
    }
    
    private func presentShareActivityViewController() {
        let context = ShareRouteActivityViewRepresentable(route: route.detail)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .presentAnyModalViewController, object: self, userInfo: [AnyModalViewObserver.Keys.context: context])
        }
    }
}

struct RouteDetailsView_Previews: PreviewProvider {
    static var testTrailContent: AuthoredActivityContent {
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
    
    static var testSportRoute: RouteDetail {
        return RouteDetail(source: .trailActivity(content: testTrailContent))
    }
    
    static var testSportState: RouteGuidanceStateStore {
        var state = RouteGuidanceState(id: testTrailContent.id)
        state.totalTime = 60 * 27 + 41
        state.visited.append(0)
        state.waypointIndex = 1
        
        return RouteGuidanceStateStore(designData: testSportRoute.id, state: state)
    }
    
    static var testOMRoute: RouteDetail {
        let waypoints = [
            ActivityWaypoint(coordinate: .init(latitude: 47.622111, longitude: -122.341000),
                             name: "9th and Harrison",
                             description: "This intersection has controls and a curb ramp"),
            ActivityWaypoint(coordinate: .init(latitude: 47.622031, longitude: -122.341100),
                             name: "Serious Pie",
                             description: "You will smell pizza baking as you walk past this restaurant"),
            ActivityWaypoint(coordinate: .init(latitude: 47.621901, longitude: -122.341150),
                             name: "Bike Rack on Westlake",
                             description: "This bike rack is in the middle of the sidewalk. Use your cane to detect it")
        ]
        
        let details = waypoints.map { wpt -> LocationDetail in
            let detail = ImportedLocationDetail(nickname: wpt.name,
                                                annotation: wpt.description,
                                                departure: wpt.departureCallout,
                                                arrival: wpt.arrivalCallout)
            
            return LocationDetail(location: CLLocation(wpt.coordinate),
                                  imported: detail,
                                  telemetryContext: "route_detail")
        }
        
        return RouteDetail(source: .database(id: ""),
                           designData: .init(id: UUID().uuidString,
                                             name: "Route from Home to the Store",
                                             description: "This is the route from your home to the grocery store. Make sure to listen for traffic at the intersections along Westlake!",
                                             waypoints: details))
    }
    
    static var testOMState: RouteGuidanceStateStore {
        var state = RouteGuidanceState(id: testOMRoute.id)
        state.totalTime = 60 * 12 + 13
        state.waypointIndex = 0
        
        return RouteGuidanceStateStore(designData: testOMRoute.id, state: state)
    }
    
    static var previews: some View {
        RouteDetailsView(testSportRoute, deleteAction: nil, designState: testSportState)
            .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
            .previewDisplayName("Trail Activity")
            .previewLayout(.sizeThatFits)
        
        RouteDetailsView(testSportRoute, deleteAction: nil, designState: testSportState)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
            .previewDisplayName("Trail Activity")
            .previewLayout(.sizeThatFits)
        
        NavigationView {
            RouteDetailsView(testSportRoute, deleteAction: nil, designState: testSportState)
                .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
                .previewDisplayName("Trail Activity")
        }
        
        NavigationView {
            RouteDetailsView(testOMRoute, deleteAction: nil, designState: testOMState)
                .navigationTitle(GDLocalizedTextView("behavior.experiences.route_nav_title"))
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(UserLocationStore(designValue: CLLocation(latitude: 47.622181, longitude: -122.341060)))
        }
        .previewDisplayName("O&M Route")
    }
}
