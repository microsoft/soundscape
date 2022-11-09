//
//  EditWaypointItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct EditWaypointItemStyleConfiguration: LocationItemStyleConfiguration {
    
    let index: Int
    
    var rightAccessory: some View {
        // Use an empty view (`customAccessorySize` is 0.0) to include an additional accessibility
        // label in the item view
        return VStack { }
        .accessibilityLabel(GDLocalizedTextView("location_detail.waypoint", "\(index + 1)"))
    }
    
    var leftAccessory: some View {
        return EmptyView()
    }
    
    let customAccessorySize: CGFloat? = 0.0
    let backgroundColor: Color = .primaryBackground
    let accessibilityHint: String? = nil
    let customAccessibilitySortPriority: LocationItemViewAccessibilitySortPriority? = nil
    let customAccessibilityTraits: AccessibilityTraits? = nil
    
}
