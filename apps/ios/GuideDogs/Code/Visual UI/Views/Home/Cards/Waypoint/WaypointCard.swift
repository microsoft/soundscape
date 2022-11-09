//
//  WaypointCard.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import SDWebImageSwiftUI

struct WaypointCard: View {
    
    // MARK: Properties
    
    @Environment(\.colorPalette) var colorPalette
    @State private var isWaypointDetailViewPresented = false
    
    let waypoint: WaypointDetail
    let isCurrent: Bool
    private let config: LocationDetailConfiguration
    
    private var mediaAccessibilityLabel: String? {
        guard let location = waypoint.locationDetail else {
            return nil
        }
        
        if location.hasImages, location.hasAudio {
            return GDLocalizedString("waypoint.audio_images_available")
        } else if location.hasImages {
            return GDLocalizedString("waypoint.images_available")
        } else if location.hasAudio {
            return GDLocalizedString("waypoint.audio_available")
        }
        
        return nil
    }
    
    // MARK: Initialization
    
    init(waypoint: WaypointDetail, isCurrent: Bool) {
        self.waypoint = waypoint
        self.isCurrent = isCurrent
        self.config = LocationDetailConfiguration(for: .waypoint(detail: waypoint), isDetailViewEnabled: false)
    }
    
    // MARK: `body`
    
    var body: some View {
        if let location = waypoint.locationDetail {
            VStack(spacing: 12.0) {
                HStack(spacing: 12.0) {
                    LocationDetailHeader(config: config)
                        .accessibilityElement(children: .combine)
                    
                    Spacer()
                    
                    if isCurrent {
                        Button {
                            GDATelemetry.track("waypoint_card.callout.selected")
                            
                            repeatLastCallout()
                        } label: {
                            Text(Image(systemName: "arrow.counterclockwise"))
                                .roundedContrastText()
                        }
                        .accessibilityLabel(GDLocalizedString("waypoint.callout.button.title"))
                        .accessibilityHint(GDLocalizedString("waypoint.callout.button.hint"))
                    }
                }
                .padding(12.0)
                
                Spacer()
                
                if let annotation = location.annotation {
                    Text(annotation)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .padding(12.0)
                }
                
                Button {
                    GDATelemetry.track("waypoint_card.detail_view.selected")
                    
                    isWaypointDetailViewPresented = true
                } label: {
                    AccessibilityHStack(horizontalAlignment: .leading, spacing: 18.0) {
                        HStack(spacing: 18.0) {
                            if location.hasImages {
                                Text(Image(systemName: "photo.on.rectangle.angled"))
                                    .font(.title3)
                            }
                            
                            if location.hasAudio {
                                Text(Image(systemName: "play.circle"))
                                    .font(.title3)
                            }
                            
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .ifLet(mediaAccessibilityLabel, transform: { $0.accessibilityLabel($1) })
                        
                        HStack(spacing: 8.0) {
                            GDLocalizedTextView("callouts.action.more_info")
                                .foregroundColor(colorPalette.light)
                            
                            Text(Image(systemName: "info.circle"))
                                .foregroundColor(colorPalette.light)
                        }
                    }
                    .roundedContrastText(padding: 18.0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(colorPalette.neutralContrast)
            .background(colorPalette.dark)
            .sheet(isPresented: $isWaypointDetailViewPresented) {
                config.detailView
                    .asModalNavigationView(isPresented: $isWaypointDetailViewPresented)
            }
            .onReceive(NotificationCenter.default.publisher(for: .tourWillEnd)) { _ in
                isWaypointDetailViewPresented = false
            }
        } else {
            // Unexpected state
            EmptyView()
        }
    }
    
    // MARK: Actions
    
    private func repeatLastCallout() {
        guard let detail = waypoint.routeDetail as? TourDetail else {
            return
        }
        
        guard let tour = detail.guidance else {
            return
        }
        
        tour.repeatLastBeaconCallout()
    }
    
}

struct WaypointCard_Previews: PreviewProvider {
    
    static let waypoint1 = WaypointDetail(index: 0, routeDetail: WaypointDetailView_Previews.route)
    static let waypoint2 = WaypointDetail(index: 1, routeDetail: WaypointDetailView_Previews.route)
    
    static var previews: some View {
        NavigationView {
            VStack(spacing: 8.0) {
                WaypointCard(waypoint: waypoint2, isCurrent: true)
                    .colorPalette(Palette.Theme.teal)
                    .frame(height: 264.0)
                    .roundedBorder(lineColor: Color.Theme.lightTeal)
                
                WaypointCard(waypoint: waypoint1, isCurrent: false)
                    .frame(height: 264.0)
                    .roundedBorder(lineColor: Color.Theme.lightBlue)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 18.0)
            .background(Color.Theme.darkBlue.ignoresSafeArea())
        }
        
        NavigationView {
            VStack(spacing: 8.0) {
                WaypointCard(waypoint: waypoint2, isCurrent: true)
                    .colorPalette(Palette.Theme.teal)
                    .frame(height: 264.0)
                    .roundedBorder(lineColor: Color.Theme.lightTeal)
                
                WaypointCard(waypoint: waypoint1, isCurrent: false)
                    .frame(height: 264.0)
                    .roundedBorder(lineColor: Color.Theme.lightBlue)
                    .foregroundColor(.white)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 18.0)
            .background(Color.Theme.darkBlue.ignoresSafeArea())
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
}
