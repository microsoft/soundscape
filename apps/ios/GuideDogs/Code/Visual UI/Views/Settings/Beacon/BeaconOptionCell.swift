//
//  BeaconOptionCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct BeaconOptionButtonStyle: ButtonStyle {
    let name: String
    let isSelected: Bool
    
    public func makeBody(configuration: BeaconOptionButtonStyle.Configuration) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .foregroundColor(!configuration.isPressed ? .primaryForeground : .primaryBackground)
                        .font(.body)
                        .lineLimit(nil)
                }
                .padding()
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(!configuration.isPressed ? .primaryForeground : .primaryBackground)
                        .padding()
                        .accessibilityHidden(true)
                }
            }
            
            Rectangle()
                .fill(Color.secondaryBackground)
                .frame(width: .infinity, height: 1)
                .padding(.leading)
        }
        .background(!configuration.isPressed ? Color.primaryBackground : Color.primaryForeground)
        .accessibilityElement(children: .combine)
    }
}

struct BeaconOptionCell: View {
    
    let type: String
    let displayName: String
    
    @Binding var selectedType: String
    
    let onSelected: (() -> Void)?
    
    var body: some View {
        Button(action: {
            SettingsContext.shared.selectedBeacon = type
            selectedType = type
            
            onSelected?()
            
            GDATelemetry.track("settings.select_beacon", value: type)
        }, label: {
            // No-op - label is set by `BeaconOptionButtonStyle`
        })
        .buttonStyle(BeaconOptionButtonStyle(name: displayName, isSelected: type == selectedType))
        .accessibilityAddTraits(type == selectedType ? [.isSelected] : [])
    }
}
struct BeaconOptionCell_Previews: PreviewProvider {
    static var previews: some View {
        BeaconOptionCell(type: "test",
                         displayName: "Test",
                         selectedType: .constant("test"),
                         onSelected: nil)
    }
}
