//
//  BeaconOption+Style.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension BeaconOption {
    
    enum Style: String {
        case standard
        case haptic
    }
    
    var style: Style {
        switch self {
        case .wand, .pulse: return .haptic
        default: return .standard
        }
    }
    
    static func allCases(for style: Style) -> [BeaconOption] {
        return BeaconOption.allCases.filter({ return $0.style == style })
    }
    
    // MARK: Availability
    
    static func isAvailable(style: Style) -> Bool {
        switch style {
        case .standard: return true
        case .haptic: return HapticEngine.supportsHaptics
        }
    }
    
    static var allAvailableCases: [BeaconOption] {
        return BeaconOption.allCases.filter({ return isAvailable(style: $0.style) })
    }
    
    static func allAvailableCases(for style: Style) -> [BeaconOption] {
        guard isAvailable(style: style) else {
            return []
        }
        
        return BeaconOption.allCases(for: style)
    }
    
}
