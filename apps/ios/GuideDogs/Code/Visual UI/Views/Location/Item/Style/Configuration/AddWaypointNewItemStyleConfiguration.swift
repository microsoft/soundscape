//
//  AddWaypointNewItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct AddWaypointNewItemStyleConfiguration: LocationItemStyleConfiguration {
    
    var rightAccessory: some View {
        return VStack {
            Image("ic_markers_28px")
            .resizable()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GDLocalizedTextView("markers.generic_name"))
    }
    
    var leftAccessory: some View {
        return Image(systemName: "plus.circle")
            .resizable()
            .foregroundColor(Color.primaryForeground)
            .accessibilityHidden(true)
    }
    
    let customAccessorySize: CGFloat? = nil
    let backgroundColor: Color = .primaryBackground
    let accessibilityHint: String? = GDLocalizedString("location_detail.add_waypoint.new.hint")
    let customAccessibilitySortPriority: LocationItemViewAccessibilitySortPriority? = nil
    let customAccessibilityTraits: AccessibilityTraits? = .isButton
    
}
