//
//  TourCardContainer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct TourCardContainer: View {
    
    // MARK: Properties
    
    @Environment(\.colorPalette) var colorPalette
    @ObservedObject private var viewModel: TourViewModel
    
    private let tour: GuidedTour
    
    // MARK: Initialization
    
    init(tour: GuidedTour) {
        self.tour = tour
        viewModel = TourViewModel(tour: tour)
    }
    
    // MARK: `body`
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24.0) {
                BeaconCard(style: .tour(behavior: tour))
                    .colorPalette(colorPalette)
                    .frame(minHeight: 264.0, maxHeight: .infinity)
                    .roundedBorder(lineColor: Palette.Theme.teal.light)
                
                if let waypoint = viewModel.currentWaypointDetail {
                    WaypointCard(waypoint: waypoint, isCurrent: true)
                }
            }
        }
    }
    
}

struct TourCardContainer_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            TourCardContainer(tour: BeaconMapView_Previews.behavior)
                .colorPalette(Palette.Theme.teal)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 12.0)
        .background(Color.Theme.darkBlue.ignoresSafeArea())
    }
    
}
