//
//  BeaconView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct BeaconView: View {
    
    // MARK: Properties
    
    @ScaledMetric(relativeTo: .body) private var buttonSize: CGFloat = 28.0
    @EnvironmentObject var userLocationStore: UserLocationStore
    @EnvironmentObject var beaconStore: BeaconDetailStore
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    // MARK: `Body`
    
    var body: some View {
        if let beacon = beaconStore.beacon {
            ZStack {
                VStack {
                    HStack {
                        BeaconTitleViewRepresentable()
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxHeight: .infinity)
                        
                        Spacer()
                        
                        Button(action: {
                            BeaconActionHandler.remove(detail: beacon)
                        }, label: {
                            Image("ic_clear_white")
                                .resizable()
                                .frame(width: buttonSize, height: buttonSize, alignment: .center)
                                .padding(8)
                        })
                        .accessibilityLabel(Text(BeaconAction.remove(source: beacon.routeDetail?.source).text))
                        .accessibilityHint(Text(BeaconAction.remove(source: beacon.routeDetail?.source).accessibilityHint ?? ""))
                        .accessibility(identifier: GDLocalizationUnnecessary("btn.removebeacon"))
                    }
                    
                    ExpandableMapView(style: beacon.toMapStyle, isExpanded: false, isEditable: false, isMapsButtonHidden: true)
                        .cornerRadius(5.0)
                        .frame(height: 180)
                    
                    BeaconToolbarView(beacon: beacon)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(10.0)
            .background(Color.primaryBackground)
            .foregroundColor(Color.primaryForeground)
            .font(.body)
            .cornerRadius(5.0)
        }
    }
    
}

struct BeaconView_Previews: PreviewProvider {
    
    static var userLocation: CLLocation {
        return CLLocation(latitude: 47.640179, longitude: -122.111320)
    }
    
    static var locationDetail: LocationDetail {
        let location = CLLocation(latitude: 47.640179, longitude: -122.111320)
        let importedDetail = ImportedLocationDetail(nickname: "Home", annotation: "This is an annotation.")
        
        return LocationDetail(location: location, imported: importedDetail, telemetryContext: nil)
    }
    
    static var adaptiveSportsBehavior: RouteGuidance {
        let route = RouteDetailsView_Previews.testSportRoute
        
        var state = RouteGuidanceState(id: route.id)
        state.totalTime = 60 * 27 + 41
        state.visited.append(0)
        state.waypointIndex = 1
        
        let guidance = RouteGuidance(route,
                                     spatialData: AppContext.shared.spatialDataContext,
                                     motion: AppContext.shared.motionActivityContext)
        guidance.state = state
        
        return guidance
    }
    
    static var previews: some View {
        BeaconView()
            .environmentObject(UserLocationStore(designValue: userLocation))
            .environmentObject(BeaconDetailStore(beacon: BeaconDetail(locationDetail: locationDetail, isAudioEnabled: true)))
            .environmentObject(ViewNavigationHelper())
        
        BeaconView()
            .environmentObject(UserLocationStore(designValue: userLocation))
            .environmentObject(BeaconDetailStore(beacon: BeaconDetail(from: adaptiveSportsBehavior, isAudioEnabled: true)))
            .environmentObject(ViewNavigationHelper())
    }
    
}
