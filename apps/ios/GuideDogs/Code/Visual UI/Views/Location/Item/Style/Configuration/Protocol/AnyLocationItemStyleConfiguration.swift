//
//  AnyLocationItemStyleConfiguration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

//
// Type-erased wrapper for the `LocationItemStyleConfiguration` class
//
struct AnyLocationItemStyleConfiguration: LocationItemStyleConfiguration {

    typealias Left = AnyView
    typealias Right = AnyView
    
    let leftAccessory: AnyView
    let rightAccessory: AnyView
    let customAccessorySize: CGFloat?
    let backgroundColor: Color
    let accessibilityHint: String?
    let customAccessibilitySortPriority: LocationItemViewAccessibilitySortPriority?
    let customAccessibilityTraits: AccessibilityTraits?
    
    init<Configuration: LocationItemStyleConfiguration>(from configuration: Configuration) {
        leftAccessory = AnyView(configuration.leftAccessory)
        rightAccessory = AnyView(configuration.rightAccessory)
        customAccessorySize = configuration.customAccessorySize
        backgroundColor = configuration.backgroundColor
        accessibilityHint = configuration.accessibilityHint
        customAccessibilitySortPriority = configuration.customAccessibilitySortPriority
        customAccessibilityTraits = configuration.customAccessibilityTraits
    }
    
}
