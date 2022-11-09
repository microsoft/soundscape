//
//  CardinalDirection.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// Represents an 8-wind compass rose
enum CardinalDirection: String, CaseIterable {
    case north     = "n"
    case northEast = "ne"
    case east      = "e"
    case southEast = "se"
    case south     = "s"
    case southWest = "sw"
    case west      = "w"
    case northWest = "nw"
}

// MARK: - Custom Initialization

extension CardinalDirection {
    
    private static let allCardialDirections = CardinalDirection.allCases // 8
    private static let angularWindowRange = 360.0 / Double(allCardialDirections.count) // 45°
    private static let halfAngularWindowRange = angularWindowRange / 2.0 // 22.5°

    init?(direction: CLLocationDirection) {
        guard direction >= 0.0 && direction <= 360.0 else {
            return nil
        }
        
        let adjustedDirection = fmod(direction + CardinalDirection.halfAngularWindowRange, 360.0)
        let directionIndex = Int(adjustedDirection / CardinalDirection.angularWindowRange)
        self = CardinalDirection.allCardialDirections[directionIndex]
    }
    
}

// MARK: - String Output

extension CardinalDirection {
    
    var localizedString: String {
        switch self {
        case .north:     return GDLocalizedString("directions.cardinal.north")
        case .northEast: return GDLocalizedString("directions.cardinal.north_east")
        case .east:      return GDLocalizedString("directions.cardinal.east")
        case .southEast: return GDLocalizedString("directions.cardinal.south_east")
        case .south:     return GDLocalizedString("directions.cardinal.south")
        case .southWest: return GDLocalizedString("directions.cardinal.south_west")
        case .west:      return GDLocalizedString("directions.cardinal.west")
        case .northWest: return GDLocalizedString("directions.cardinal.north_west")
        }
    }
    
    var localizedAbbreviatedString: String {
        switch self {
        case .north:     return GDLocalizedString("directions.cardinal.north.abb")
        case .northEast: return GDLocalizedString("directions.cardinal.north_east.abb")
        case .east:      return GDLocalizedString("directions.cardinal.east.abb")
        case .southEast: return GDLocalizedString("directions.cardinal.south_east.abb")
        case .south:     return GDLocalizedString("directions.cardinal.south.abb")
        case .southWest: return GDLocalizedString("directions.cardinal.south_west.abb")
        case .west:      return GDLocalizedString("directions.cardinal.west.abb")
        case .northWest: return GDLocalizedString("directions.cardinal.north_west.abb")
        }
    }
    
}
