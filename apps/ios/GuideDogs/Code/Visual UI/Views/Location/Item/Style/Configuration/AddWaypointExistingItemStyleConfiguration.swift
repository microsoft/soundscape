//
//  AddWaypointExistingItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct AddWaypointExistingItemStyleConfiguration: LocationItemStyleConfiguration {
    
    let index: Int
    
    var rightAccessory: some View {
        return VStack {
            Image(systemName: "circle")
                .resizable()
                .aspectRatio(1.0, contentMode: .fill)
                .foregroundColor(.primaryForeground)
                .overlay(
                    Text("\(index + 1)")
                        .accessibleTextFormat()
                        .font(.body)
                        .foregroundColor(.white)
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GDLocalizedTextView("location_detail.waypoint", "\(index + 1)"))
    }
    
    var leftAccessory: some View {
        return Image(systemName: "checkmark")
            .resizable()
            .foregroundColor(Color.greenHighlight)
            .padding(4.0)
            .accessibilityHidden(true)
    }
    
    let customAccessorySize: CGFloat? = nil
    let backgroundColor: Color = .tertiaryBackground
    let accessibilityHint: String? = GDLocalizedString("location_detail.add_waypoint.existing.hint")
    let customAccessibilitySortPriority: LocationItemViewAccessibilitySortPriority? = nil
    let customAccessibilityTraits: AccessibilityTraits? = AccessibilityTraits(arrayLiteral: .isButton, .isSelected)
    
}
