//
//  AccessibilityEditableMapViewModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

class AccessibilityEditableMapViewModel: ObservableObject {
    
    enum Direction: String {
        case north
        case south
        case east
        case west
        case compass
        
        var degrees: Double? {
            switch self {
            case .north: return 0.0
            case .south: return 180.0
            case .east: return 90.0
            case .west: return 270.0
            case .compass: return AppContext.shared.geolocationManager.heading(orderedBy: [.device]).value
            }
        }
    }
    
    // MARK: Properties
    
    @Published var direction: Direction = .compass
    
}
