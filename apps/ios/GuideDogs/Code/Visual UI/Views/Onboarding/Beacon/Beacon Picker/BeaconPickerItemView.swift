//
//  BeaconPickerItemView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct BeaconPickerItemView: View {
    
    // MARK: Properties
    
    let beacon: BeaconOption
    let isSelected: Bool
    private let dividerColor: Color?
    
    // MARK: Initialization
    
    init(beacon: BeaconOption, isSelected: Bool) {
        self.beacon = beacon
        self.isSelected = isSelected
        // Use default value
        self.dividerColor = nil
    }
    
    private init(beacon: BeaconOption, isSelected: Bool, dividerColor: Color) {
        self.beacon = beacon
        self.isSelected = isSelected
        self.dividerColor = dividerColor
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 12.0) {
                Image(systemName: "checkmark")
                    .if(!isSelected, transform: { $0.hidden() })
                    .accessibility(hidden: true)
                
                Text(beacon.localizedName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.center)
                    .accessibleTextFormat()
                    .accessibilityLabel(isSelected ? GDLocalizedString("filter.selected", beacon.localizedName) : beacon.localizedName)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .accessibility(hidden: true)
            }
            .padding(.horizontal, 18.0)
            .padding(.vertical, 12.0)
            
            Divider()
                .background(dividerColor)
                .padding(.horizontal, 8.0)
        }
        .accessibilityElement(children: .combine)
    }
    
}

struct BeaconPickerItemView_Previews: PreviewProvider {
    
    static var previews: some View {
        ZStack {
            VStack(spacing: 0.0) {
                // Selected item
                BeaconPickerItemView(beacon: .current, isSelected: true)
                    .background(Color.primaryForeground)
                    .foregroundColor(Color.primaryBackground)
                
                // Item is not selected
                // Try different colors
                BeaconPickerItemView(beacon: .flare, isSelected: false)
                    .dividerColor(.greenHighlight)
                    .linearGradientBackground(.blue)
                    .foregroundColor(Color.primaryForeground)
            }
            .cornerRadius(5.0)
            .padding(24.0)
        }
        .linearGradientBackground(.purple, ignoresSafeArea: true)
    }
    
}

extension BeaconPickerItemView {
    
    func dividerColor(_ dividerColor: Color) -> some View {
        BeaconPickerItemView(beacon: self.beacon, isSelected: self.isSelected, dividerColor: dividerColor)
    }
    
}
