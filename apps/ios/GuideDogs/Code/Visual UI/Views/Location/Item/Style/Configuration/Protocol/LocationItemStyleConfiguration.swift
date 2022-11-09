//
//  LocationItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

protocol LocationItemStyleConfiguration {
    
    associatedtype Left: View
    associatedtype Right: View

    @ViewBuilder var leftAccessory: Left { get }
    @ViewBuilder var rightAccessory: Right { get }
    var customAccessorySize: CGFloat? { get }
    var backgroundColor: Color { get }
    var accessibilityHint: String? { get }
    var customAccessibilitySortPriority: LocationItemViewAccessibilitySortPriority? { get }
    var customAccessibilityTraits: AccessibilityTraits? { get }
    
}

extension LocationItemStyleConfiguration {
    
    var wrapper: AnyLocationItemStyleConfiguration {
        return AnyLocationItemStyleConfiguration(from: self)
    }
    
}
