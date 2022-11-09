//
//  TourToolbar.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct TourToolbar: View {
    
    // MARK: Properties
    
    @Environment(\.colorPalette) var colorPalette
    @EnvironmentObject private var userLocation: UserLocationStore
    @ObservedObject private var viewModel: TourViewModel
    @State private var elapsedTime: TimeInterval
    
    let tour: GuidedTour
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private var distanceText: String? {
        return viewModel.currentWaypointLocation?.labels.distance(from: userLocation.location)?.text
    }
    
    private var elapsedText: String? {
        let elapsed = DateComponentsFormatter.timeElapsedFormatter.string(from: elapsedTime)
        
        if tour.isActive {
            guard let elapsed = elapsed else {
                return nil
            }
            
            return GDLocalizedString("route.title.time", elapsed)
        } else if let elapsed = elapsed {
            return GDLocalizedString("route.waypoint.progress.complete.elapsed", elapsed)
        } else {
            return GDLocalizedString("route.waypoint.progress.complete")
        }
    }
    
    private var progressTextAccessibility: String? {
        // Initialize elapsed text
        let formatter = DateComponentsFormatter.accessibilityTimeElapsedFormatter
        let elapsedAccessibility = formatter.string(from: elapsedTime)
        
        if viewModel.isComplete {
            if let elapsedAccessibility = elapsedAccessibility {
                return GDLocalizedString("route.waypoint.progress.complete.elapsed", elapsedAccessibility)
            } else {
                return GDLocalizedString("route.waypoint.progress.complete")
            }
        } else {
            guard let waypoint = viewModel.currentWaypointLocation else {
                return nil
            }
            
            // Initialize distance text
            let label = waypoint.labels.distance(from: userLocation.location)
            let distanceAccessibility = label?.accessibilityText ?? label?.text
            
            // Initialize remaining text
            let remainingInt = viewModel.nWaypoint - viewModel.nCompleted
            let remaining = "\(remainingInt)"
            
            if let elapsedAccessibility = elapsedAccessibility, let distanceAccessibility = distanceAccessibility {
                return remainingInt > 1 ? GDLocalizedString("tour.progress.elapsed_distance.accessibility", waypoint.displayName, distanceAccessibility, elapsedAccessibility, remaining) : GDLocalizedString("tour.progress.elapsed_distance.accessibility.singular", waypoint.displayName, distanceAccessibility, elapsedAccessibility)
            } else if let elapsedAccessibility = elapsedAccessibility {
                return remainingInt > 1 ? GDLocalizedString("tour.progress.elapsed.accessibility", waypoint.displayName, elapsedAccessibility, remaining) : GDLocalizedString("tour.progress.elapsed.accessibility.singular", waypoint.displayName, elapsedAccessibility)
            } else if let distanceAccessibility = distanceAccessibility {
                return remainingInt > 1 ? GDLocalizedString("tour.progress.distance.accessibility", waypoint.displayName, distanceAccessibility, remaining) : GDLocalizedString("tour.progress.distance.accessibility.singular", waypoint.displayName, distanceAccessibility)
            } else {
                return remainingInt > 1 ? GDLocalizedString("tour.progress.accessibility", waypoint.displayName, remaining) : GDLocalizedString("tour.progress.accessibility.singular", waypoint.displayName)
            }
        }
    }
    
    // MARK: Initialization
    
    init(tour: GuidedTour) {
        self.tour = tour
        viewModel = TourViewModel(tour: tour)
        elapsedTime = tour.runningTime
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(spacing: 12.0) {
            VStack(spacing: 0.0) {
                if #available(iOS 15.0, *) {
                    ProgressView(value: Float(viewModel.nCompleted), total: Float(viewModel.nWaypoint))
                        .tint(colorPalette.light)
                        .background(colorPalette.dark)
                        .padding(.top, 2.0)
                        .accessibilityHidden(true)
                } else {
                    ProgressView(value: Float(viewModel.nCompleted), total: Float(viewModel.nWaypoint))
                        .padding(.top, 2.0)
                        .accessibilityHidden(true)
                }
                
                AccessibilityHStack(horizontalAlignment: .leading, spacing: 4.0) {
                    if let distanceText = distanceText {
                        Image(systemName: "location.north.circle")
                            .font(.footnote)
                            .accessibilityHidden(true)
                        
                        Text(distanceText)
                            .font(.callout)
                            .accessibilityHidden(true)
                    }
                    
                    Spacer()
                    
                    if let elapsedText = elapsedText {
                        Image(systemName: "timer")
                            .font(.footnote)
                            .accessibilityHidden(true)
                        
                        Text(elapsedText)
                            .font(.callout)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12.0)
                .padding(.top, 12.0)
            }
            .accessibilityElement(children: .combine)
            .ifAvailableAccessibilityRespondsToUserInteraction(false)
            .ifLet(progressTextAccessibility, transform: { $0.accessibilityLabel($1) })
            
            AccessibilityHStack(horizontalAlignment: .leading, spacing: 18.0) {
                HStack(spacing: 18.0) {
                    // Previous
                    Button {
                        GDATelemetry.track("tour_toolbar.previous.selected")
                        
                        tour.previousWaypoint()
                    } label: {
                        Text(Image(systemName: "backward.end"))
                            .font(.title2)
                    }
                    .disabledButtonStyle(viewModel.isTransitioning || viewModel.isFirstWaypoint)
                    .accessibilityLabel(GDLocalizedTextView("route_detail.action.previous"))
                    .accessibilityHint(GDLocalizedTextView("route_detail.action.previous.hint"))
                    
                    // Next
                    Button {
                        GDATelemetry.track("tour_toolbar.next.selected")
                        
                        tour.nextWaypoint()
                    } label: {
                        Text(Image(systemName: "forward.end"))
                            .font(.title2)
                    }
                    .disabledButtonStyle(viewModel.isTransitioning || viewModel.isLastWaypoint)
                    .accessibilityLabel(GDLocalizedTextView("route_detail.action.next"))
                    .accessibilityHint(GDLocalizedTextView("route_detail.action.next.hint"))
                    
                    // Audio Beacon
                    Button {
                        GDATelemetry.track("tour_toolbar.toggle_audio.selected", with: ["isPlaying": (!AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled).description])
                        
                        withAnimation {
                            BeaconActionHandler.toggleAudio()
                        }
                    } label: {
                        Text(Image(systemName: viewModel.isAudioBeaconEnabled ? "speaker.wave.2" : "speaker.slash"))
                            .font(.title2)
                    }
                    .disabledButtonStyle(viewModel.isTransitioning)
                    .accessibilityLabel(GDLocalizedString(viewModel.isAudioBeaconEnabled ? "beacon.action.mute_beacon" : "beacon.action.unmute_beacon"))
                    .accessibilityHint(GDLocalizedString(viewModel.isAudioBeaconEnabled ? "beacon.action.mute_beacon.acc_hint" : "beacon.action.unmute_beacon.acc_hint"))
                    
                    Spacer()
                }
                
                Button {
                    GDATelemetry.track("tour_toolbar.end.selected", with: ["is_completed": tour.state.isFinal.description])
                    
                    AppContext.shared.eventProcessor.deactivateCustom()
                } label: {
                    GDLocalizedTextView("tour_detail.beacon.stop")
                }
                .roundedBackground(padding: 8.0, Color.Theme.orange)
            }
            .padding(.horizontal, 12.0)
            .padding(.bottom, 12.0)
        }
        .foregroundColor(colorPalette.neutralContrast)
        .background(colorPalette.color)
        .onReceive(timer) { _ in
            self.elapsedTime = tour.runningTime
        }
    }
    
}

struct TourToolbar_Previews: PreviewProvider {
    
    static var previews: some View {
        TourToolbar(tour: BeaconMapView_Previews.behavior)
            .colorPalette(Palette.Theme.teal)
            .frame(maxWidth: .infinity)
            .padding(24.0)
            .cornerRadius(5.0)
        
        TourToolbar(tour: BeaconMapView_Previews.behavior)
            .colorPalette(Palette.Theme.teal)
            .frame(maxWidth: .infinity)
            .padding(24.0)
            .cornerRadius(5.0)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
}

private extension View {
    
    ///
    /// Applies the given transformation if iOS 15 is available
    ///
    /// Parameters
    /// - transform: closure that applies the transformation
    ///
    @ViewBuilder
    func ifAvailableAccessibilityRespondsToUserInteraction(_ value: Bool) -> some View {
        if #available(iOS 15, *) {
            self.accessibilityRespondsToUserInteraction(value)
        }
    }
    
}
