//
//  PlainLocationItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct PlainLocationItemStyleConfiguration: LocationItemStyleConfiguration {
    
    var rightAccessory: some View {
        return EmptyView()
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
