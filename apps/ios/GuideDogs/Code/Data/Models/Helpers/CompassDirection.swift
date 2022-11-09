//
//  CompassDirection.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

enum CompassDirection: Int {
    case north = 0
    case east = 1
    case south = 2
    case west = 3
    case unknown = 4
    
    static let allDirections: [CompassDirection] = [.north, .east, .south, .west]
    
    /// Returns the CompassDirection for the bearing to a POI
    ///
    /// - Parameters:
    ///   - bearing: Bearing to POI
    ///   - quadrants: Array of 4 quadrants
    /// - Returns: The CompassDirection of the bearing
    static func from(bearing: CLLocationDirection, quadrants: [Quadrant] = SpatialDataView.getQuadrants(heading: 0.0)) -> CompassDirection {
        guard let index = quadrants.firstIndex(where: { $0.contains(bearing) }), index < 4 else {
            return .unknown
        }
        
        return CompassDirection.init(rawValue: index)!
    }
}
