//
//  WaypointAddList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation
import RealmSwift

struct WaypointAddList: View {
    
    // MARK: Properties
    
    @ObservedObject private var viewModel: WaypointAddListViewModel
    
    // MARK: Initialization
    
    init(waypoints: Binding<[IdentifiableLocationDetail]>) {
        viewModel = WaypointAddListViewModel(waypoints: waypoints)
        
        // Fill empty space in the list view
        UITableView.appearance().backgroundColor = Colors.Background.tertiary!
        
        // Disable vertical bounce when scrolling is not needed
        UIScrollView.appearance().alwaysBounceVertical = false
    }
    
    // MARK: `body`
    
    var body: some View {
        ZStack {
            // Background color that extends past the safe area
            Color.tertiaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0.0) {
                GDLocalizedTextView("markers.title")
                    .frame(minWidth: 0.0, maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.primaryForeground)
                    .font(.callout)
                    .padding(.horizontal, 18.0)
                    .padding(.vertical, 12.0)
                    .background(Color.secondaryBackground)
                    .accessibleTextFormat()
                    .accessibilityAddTraits(.isHeader)
                
                List {
                    if viewModel.markers.count > 0 {
                        // All markers have been fetched
                        ForEach(viewModel.markers) { element in
                            let userLocation = AppContext.shared.geolocationManager.location
                            
                            LocationItemView(locationDetail: element.locationDetail, userLocation: userLocation)
                                .locationItemStyle(.addWaypoint(index: element.index))
                                .onTapGesture {
                                    if let index = element.index {
                                        // Remove waypoint
                                        viewModel.removeWaypoint(at: index)
                                    } else {
                                        // Add waypoint
                                        viewModel.addWaypoint(element)
                                    }
                                }
                        }
                    } else if viewModel.markerStore.loadingComplete {
                        // There are no existing markers
                        EmptyMarkerOrRoutesView(.markers)
                            .frame(minHeight: 0.0, maxHeight: .infinity, alignment: .center)
                            .plainListRowBackground(Color.tertiaryBackground)
                    } else {
                        // Markers are being fetched
                        LoadingMarkersOrRoutesView()
                            .frame(minHeight: 0.0, maxHeight: .infinity, alignment: .center)
                            .plainListRowBackground(Color.tertiaryBackground)
                    }
                }
                .listStyle(PlainListStyle())
                .frame(minHeight: 0.0, maxHeight: .infinity, alignment: .top)
            }
        }
        .navigationBarTitle(GDLocalizedTextView("route_detail.edit.waypoints_button"), displayMode: .inline)
        .onAppear {
            GDATelemetry.trackScreenView("waypoint_add")
        }
    }
    
}

struct WaypointAddList_Previews: PreviewProvider {
    
    static var userLocation: CLLocation {
        return CLLocation(latitude: 47.640179, longitude: -122.111320)
    }
    
    static var previews: some View {
        
        Realm.bootstrap()
        
        AppContext.shared.geolocationManager.mockLocation(CLLocation.sample)
        
        let markerIds = SpatialDataCache.referenceEntities().compactMap({ return $0.id })
        let waypoints: [IdentifiableLocationDetail]
        
        if let id = markerIds.first, let detail = LocationDetail(markerId: id) {
            var details = RouteDetailsView_Previews.testOMRoute.waypoints
            details.append(detail)
            
            waypoints = details.asIdenfifiable
        } else {
            waypoints = RouteDetailsView_Previews.testOMRoute.waypoints.asIdenfifiable
        }
        
        return Group {
            WaypointAddList(waypoints: .constant(waypoints))
            
            WaypointAddList(waypoints: .constant([]))
        }
        .environment(\.realmConfiguration, RealmHelper.databaseConfig)
        
    }
    
}
