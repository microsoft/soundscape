//
//  BeaconPickerView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

struct BeaconPickerView: View {
    
    // MARK: Properties
    
    @Binding var selectedBeacon: BeaconOption?
    
    let allBeacons: [BeaconOption]
    
    // MARK: Initialization
    
    init(selectedBeacon: Binding<BeaconOption?>, allBeacons: [BeaconOption] = BeaconOption.allAvailablePickerCases) {
        _selectedBeacon = selectedBeacon
        self.allBeacons = allBeacons
    }
    
    // MARK: `body`
    
    var body: some View {
        ZStack {
            Color.primaryForeground
            
            ScrollView {
                VStack(spacing: 0.0) {
                    // Standard beacons
                    ForEach(allBeacons) { beacon in
                        Button {
                            GDATelemetry.track("onboarding.beacon.selected", with: ["beacon": beacon.localizedName])
                            
                            // Save selected beacon
                            selectedBeacon = beacon
                        } label: {
                            BeaconPickerItemView(beacon: beacon, isSelected: beacon == selectedBeacon)
                                .dividerColor(.primaryBackground)
                                .foregroundColor(.primaryBackground)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 300.0)
        .fixedSize(horizontal: false, vertical: true)
        .cornerRadius(5.0)
    }
    
}

struct BeaconPickerView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingContainer {
            // Beacon is selected
            BeaconPickerView(selectedBeacon: .constant(.tacticle), allBeacons: BeaconOption.allPickerCases)
        }
        
        OnboardingContainer {
            // No beacon is selected
            // Try a large font
            BeaconPickerView(selectedBeacon: .constant(nil), allBeacons: BeaconOption.allPickerCases)
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        }
    }
    
}

private extension BeaconOption {
    
    static var allPickerCases: [BeaconOption] {
        return [
            .original,
            .tacticle,
            .flare,
            .pulse
        ]
    }
    
    static var allAvailablePickerCases: [BeaconOption] {
        return allPickerCases.filter({ return BeaconOption.isAvailable(style: $0.style) })
    }
    
    var tag: Int {
        return BeaconOption.allCases.enumerated().first(where: { $0.element == self })!.offset
    }
    
}
