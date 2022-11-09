//
//  BeaconCard.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct BeaconCard: View {
    
    // MARK: Properties
    
    @Environment(\.colorPalette) var colorPalette
    
    let style: BeaconStyle
    
    // MARK: `body`
    
    var body: some View {
        VStack(spacing: 0.0) {
            BeaconMapCard(style: style.mapStyle)
            
            switch style {
            case .location, .route:
                // TODO: Add support for locations and routes
                EmptyView()
            case .tour(let behavior):
                TourToolbar(tour: behavior)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

struct BeaconCard_Previews: PreviewProvider {
    
    static let tour = BeaconMapCard_Previews.behavior
    
    static var previews: some View {
        BeaconCard(style: .tour(behavior: tour))
            .colorPalette(Palette.Theme.teal)
            .frame(height: 288.0)
            .roundedBorder(lineColor: Palette.Theme.teal.light)
            .padding(24.0)
    }
    
}
