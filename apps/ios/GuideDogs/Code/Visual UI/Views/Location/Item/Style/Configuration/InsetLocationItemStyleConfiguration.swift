//
//  InsetLocationItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct InsetLocationItemStyleConfiguration: LocationItemStyleConfiguration {
    
    var rightAccessory: some View {
        // Empty view that uses space
        return Color.clear
    }
    
    var leftAccessory: some View {
        return EmptyView()
    }
    
    let customAccessorySize: CGFloat? = nil
    let backgroundColor: Color = .primaryBackground
    let accessibilityHint: String? = nil
    let customAccessibilitySortPriority: LocationItemViewAccessibilitySortPriority? = nil
    let customAccessibilityTraits: AccessibilityTraits? = nil
    
}
