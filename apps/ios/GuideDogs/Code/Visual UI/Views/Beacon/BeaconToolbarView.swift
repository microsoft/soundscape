//
//  BeaconToolbarView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import CoreLocation

struct BeaconToolbarView: View {
    
    // MARK: Properties
    
    @ScaledMetric(relativeTo: .body) private var smallButtonSize: CGFloat = 20.0
    @ScaledMetric(relativeTo: .body) private var buttonSize: CGFloat = 28.0
    
    @EnvironmentObject var beaconStore: BeaconDetailStore
    @EnvironmentObject var navHelper: ViewNavigationHelper
    
    @State var prevDisabled: Bool
    @State var nextDisabled: Bool
    
    let beacon: BeaconDetail
    
    init(beacon: BeaconDetail) {
        self.beacon = beacon
        
        guard let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            _prevDisabled = State(initialValue: true)
            _nextDisabled = State(initialValue: true)
            return
        }
        
        let progress = routeGuidance.progress
        
        guard let current = progress.currentWaypoint else {
            _prevDisabled = State(initialValue: true)
            _nextDisabled = State(initialValue: true)
            return
        }
        
        _prevDisabled = State(initialValue: current.index == 0)
        _nextDisabled = State(initialValue: current.index == progress.total - 1)
    }
    
    // MARK: `Body`
    
    var body: some View {
        HStack(spacing: 4.0) {
            if let routeDetail = beacon.routeDetail {
                // Previous
                Button(action: {
                    routeDetail.guidance?.previousWaypoint()
                }, label: {
                    Image(systemName: "backward.end")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: smallButtonSize, maxHeight: smallButtonSize)
                        .foregroundColor(prevDisabled || beaconStore.isRouteTransitioning ? .gray : .white)
                        .padding(12)
                })
                .accessibilityLabel(GDLocalizedTextView("route_detail.action.previous"))
                .accessibilityHint(GDLocalizedTextView("route_detail.action.previous.hint"))
                .disabled(prevDisabled || beaconStore.isRouteTransitioning)
                
                // Next
                Button(action: {
                    routeDetail.guidance?.nextWaypoint()
                }, label: {
                    Image(systemName: "forward.end")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: smallButtonSize, maxHeight: smallButtonSize)
                        .foregroundColor(nextDisabled || beaconStore.isRouteTransitioning ? .gray : .white)
                        .padding(12)
                })
                .accessibilityLabel(GDLocalizedTextView("route_detail.action.next"))
                .accessibilityHint(GDLocalizedTextView("route_detail.action.next.hint"))
                .disabled(nextDisabled || beaconStore.isRouteTransitioning)
                
                // View details
                Button(action: {
                    let storyboard = UIStoryboard(name: "RecreationalActivities", bundle: Bundle.main)
                    let viewController = storyboard.instantiateViewController(withIdentifier: "RouteDetailsView")
                    
                    navHelper.pushViewController(viewController, animated: true)
                }, label: {
                    Image(systemName: "info.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: smallButtonSize, maxHeight: smallButtonSize)
                        .foregroundColor(beaconStore.isRouteTransitioning ? .gray : .white)
                        .padding(12)
                })
                .accessibilityLabel(Text(BeaconAction.viewDetails.text))
                .accessibilityHint(Text(BeaconAction.viewDetails.accessibilityHint ?? ""))
            } else {
                // Callout
                Button(action: {
                    BeaconActionHandler.callout(detail: beacon)
                }, label: {
                    Image("ic_replay_white_28px")
                        .resizable()
                        .frame(maxWidth: buttonSize, maxHeight: buttonSize, alignment: .center)
                        .padding(8)
                })
                // Included as an accessibility action on the title label
                .accessibilityHidden(true)
                
                if beacon.locationDetail.isMarker {
                    Image("ic_markers_28px")
                        .resizable()
                        .frame(maxWidth: buttonSize, maxHeight: buttonSize, alignment: .center)
                        .padding(8)
                        .accessibilityHidden(true) // Included as an accessibility action on the title label
                } else {
                    // Create marker
                    Button(action: {
                        guard let viewController = BeaconActionHandler.createMarker(detail: beacon) else {
                            return
                        }
                        
                        navHelper.pushViewController(viewController, animated: true)
                    }, label: {
                        Image("AddMarker_iconW")
                            .resizable()
                            .frame(maxWidth: buttonSize, maxHeight: buttonSize, alignment: .center)
                            .padding(8)
                    })
                    .accessibilityHidden(true) // Included as an accessibility action on the title label
                }
            }
            
            Spacer()
            
            // Toggle audio
            if beacon.isAudioEnabled {
                // Toggle audio
                Button(action: {
                    BeaconActionHandler.toggleAudio()
                }, label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: smallButtonSize + 12, maxHeight: smallButtonSize)
                        .foregroundColor(beaconStore.isRouteTransitioning ? .gray : .white)
                        .padding(8)
                })
                .accessibilityLabel(GDLocalizedTextView("beacon.action.mute_beacon"))
                .accessibilityHint(GDLocalizedTextView("beacon.action.mute_beacon.acc_hint"))
                .disabled(beaconStore.isRouteTransitioning)
            } else {
                // Toggle audio
                Button(action: {
                    BeaconActionHandler.toggleAudio()
                }, label: {
                    Image(systemName: "speaker.slash.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: smallButtonSize, maxHeight: smallButtonSize)
                        .foregroundColor(beaconStore.isRouteTransitioning ? .gray : .white)
                        .padding([.top, .bottom], 8)
                        .padding([.trailing], 12)
                })
                .accessibilityLabel(GDLocalizedTextView("beacon.action.unmute_beacon"))
                .accessibilityHint(GDLocalizedTextView("beacon.action.unmute_beacon.acc_hint"))
                .disabled(beaconStore.isRouteTransitioning)
            }
        }
        .foregroundColor(Color.primaryForeground)
        .onReceive(NotificationCenter.default.publisher(for: .routeGuidanceStateChanged)) { _ in
            self.updateBtnState()
        }
    }
    
    private func updateBtnState() {
        guard let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            return
        }
        
        let progress = routeGuidance.progress
        
        guard let current = progress.currentWaypoint else {
            prevDisabled = true
            nextDisabled = true
            return
        }
        
        prevDisabled = current.index == 0
        nextDisabled = current.index == progress.total - 1
    }
}

struct BeaconToolbarView_Previews: PreviewProvider {
    
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
        
        Group {
            BeaconToolbarView(beacon: BeaconDetail(locationDetail: locationDetail, isAudioEnabled: false))
                .environmentObject(BeaconDetailStore(beacon: BeaconDetail(from: adaptiveSportsBehavior, isAudioEnabled: true)))
            
            BeaconToolbarView(beacon: BeaconDetail(from: adaptiveSportsBehavior, isAudioEnabled: true)!)
                .environmentObject(BeaconDetailStore(beacon: BeaconDetail(from: adaptiveSportsBehavior, isAudioEnabled: true)))
        }
        .background(Color.primaryBackground)
        
    }
    
}
