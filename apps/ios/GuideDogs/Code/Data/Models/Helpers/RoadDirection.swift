//
//  RoadDirection.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import CocoaLumberjackSwift

protocol Orientable {
    var bearing: CLLocationDirection { get }
}

struct RoadDirection: Orientable {
    let road: Road
    let bearing: CLLocationDirection
    let direction: Direction
    
    init(_ road: Road, _ bearing: CLLocationDirection, _ direction: Direction) {
        self.road = road
        self.bearing = bearing
        self.direction = direction
    }
}

// MARK: - Sort Helpers

extension Direction {
    /// A clockwise sort order starting with `.behind`
    fileprivate var clockwiseSortOrder: Int {
        switch self {
        case .behind:      return 0
        case .behindLeft:  return 1
        case .left:        return 2
        case .aheadLeft:   return 3
        case .ahead:       return 4
        case .aheadRight:  return 5
        case .right:       return 6
        case .behindRight: return 7
        case .unknown:     return 8
        }
    }
}

extension RoadDirection: Comparable {
    /// Compares the road directions using a clockwise sort order starting with `.behind`
    static func < (lhs: RoadDirection, rhs: RoadDirection) -> Bool {
        return lhs.direction.clockwiseSortOrder < rhs.direction.clockwiseSortOrder
    }
    
    static func == (lhs: RoadDirection, rhs: RoadDirection) -> Bool {
        return lhs.road.key == rhs.road.key && lhs.bearing == rhs.bearing && lhs.direction == rhs.direction
    }
}
