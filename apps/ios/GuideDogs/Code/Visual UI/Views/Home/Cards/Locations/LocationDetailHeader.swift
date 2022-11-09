//
//  LocationDetailHeader.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LocationDetailHeader: View {
    
    // MARK: Properties
    
    let config: LocationDetailConfiguration
    
    // MARK: `body`
    
    var body: some View {
        HStack(spacing: 12.0) {
            VStack(alignment: .leading, spacing: 2.0) {
                Text(config.title)
                
                Text(config.subtitle)
                    .font(.caption)
            }
            .multilineTextAlignment(.leading)
            
            if config.isDetailViewEnabled {
                Text(Image(systemName: "info.circle"))
                    .font(.title3)
            }
        }
        .roundedContrastText()
        .multilineTextAlignment(.leading)
        .accessibilityAddTraits(.isHeader)
    }
    
}

struct LocationDetailHeader_Previews: PreviewProvider {
    
    static var previews: some View {
        LocationDetailHeader(config: LocationDetailConfiguration(for: .tour(detail: BeaconMapView_Previews.behavior.content)))
    }
    
}
