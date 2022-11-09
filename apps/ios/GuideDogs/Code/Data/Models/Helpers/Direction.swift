//
//  Direction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

enum RelativeDirectionType: Int {
    /// Ahead, Right, Behind, and Left all get a 150 degree window centered in their respective
    /// directions (e.g. right is 15 degrees to 165 degrees). In the areas where these windows
    /// overlap, the relative directions get combined. For example, 0 degrees is "ahead", while
    /// 10 degrees is "ahead to the right."
    case combined
    
    /// Ahead, Right, Behind, and Left all get a 90 degree window centered in their respective
    /// directions (e.g. right is from 45 degrees to 135 degrees). These windows do not overlap,
    /// so relative directions can only be "ahead", "to the right", "behind", or "to the left".
    case individual
    
    /// Ahead and Beind get a 150 degree window, while Left and Right get 30 degree windows in their
    /// respective directions (e.g. right is 75 degrees to 105 degrees and behind is 105 degrees to
    /// 255 degrees). These windows do not overlap, so relative directions can only be "ahead",
    /// "to the right", "behind", or "to the left". This style of relative direction is bias towards
    /// calling out things as either ahead or behind unless they are directly to the left or right.
    case aheadBehind
    
    /// Left and Right get a 120 degree window, while Ahead and Beind get 60 degree windows in their
    /// respective directions (e.g. right is 30 degrees to 150 degrees and behind is 150 degrees to
    /// 210 degrees). These windows do not overlap, so relative directions can only be "ahead",
    /// "to the right", "behind", or "to the left". This style of relative direction is bias towards
    /// calling out things as either left or right unless they are directly ahead or beind.
    case leftRight
}

enum Direction: Int {
    case behind, behindLeft, left, aheadLeft, ahead, aheadRight, right, behindRight, unknown
}

// MARK: - Custom Initialization

extension Direction {
    
    /// Initializes a `Direction` object by calculating the bearing between two `CLLocationDirection` objects.
    /// For example, if `direction` is 90° and `otherDirection` is 180° the result would be `Direction.right`.
    init(from direction: CLLocationDirection, to otherDirection: CLLocationDirection, type: RelativeDirectionType = .individual) {
        let relativeDirection = direction.bearing(to: otherDirection)
        self.init(from: relativeDirection, type: type)
    }
    
    /// Initializes a `Direction` object with 0° as the frame of reference (ahead).
    /// For example, if `direction` is 90° the result would be `Direction.right`.
    init(from direction: CLLocationDirection, type: RelativeDirectionType = .individual) {
        guard direction >= 0 else {
            self = .unknown
            return
        }
        
        let directionType: Direction
        
        switch type {
        case .combined:
            
            if direction > 345.0 || direction <= 15.0 {
                directionType = .ahead
            } else if direction > 15.0 && direction <= 75.0 {
                directionType = .aheadRight
            } else if direction > 75.0 && direction <= 105.0 {
                directionType = .right
            } else if direction > 105.0 && direction <= 165.0 {
                directionType = .behindRight
            } else if direction > 165.0 && direction <= 195.0 {
                directionType = .behind
            } else if direction > 195.0 && direction <= 255.0 {
                directionType = .behindLeft
            } else if direction > 255.0 && direction <= 285.0 {
                directionType = .left
            } else { // if diff > 285.0 && diff <= 345.0
                directionType = .aheadLeft
            }
            
            self = directionType
            
        case .individual:
            
            if direction > 315.0 || direction <= 45.0 {
                directionType = .ahead
            } else if direction > 45.0 && direction <= 135.0 {
                directionType = .right
            } else if direction > 135.0 && direction <= 225.0 {
                directionType = .behind
            } else { // if diff > 225.0 && diff <= 315.0
                directionType = .left
            }
            
            self = directionType
            
        case .aheadBehind:
            
            if direction > 285.0 || direction <= 75.0 {
                directionType = .ahead
            } else if direction > 75.0 && direction <= 105.0 {
                directionType = .right
            } else if direction > 105.0 && direction <= 255.0 {
                directionType = .behind
            } else { // if diff > 255.0 && diff <= 285.0
                directionType = .left
            }
            
            self = directionType
            
        case .leftRight:
            
            if direction > 330.0 || direction <= 30.0 {
                directionType = .ahead
            } else if direction > 30.0 && direction <= 150.0 {
                directionType = .right
            } else if direction > 150.0 && direction <= 210.0 {
                directionType = .behind
            } else { // if direction > 210.0 && direction <= 330.0
                directionType = .left
            }
            
            self = directionType
        }
    }
    
}

// MARK: - String Output

extension Direction {
    var localizedString: String {
        switch self {
        case .behind:      return GDLocalizedString("directions.direction.behind")
        case .behindLeft:  return GDLocalizedString("directions.direction.behind_to_the_left")
        case .left:        return GDLocalizedString("directions.direction.to_the_left")
        case .aheadLeft:   return GDLocalizedString("directions.direction.ahead_to_the_left")
        case .ahead:       return GDLocalizedString("directions.direction.ahead")
        case .aheadRight:  return GDLocalizedString("directions.direction.ahead_to_the_right")
        case .right:       return GDLocalizedString("directions.direction.to_the_right")
        case .behindRight: return GDLocalizedString("directions.direction.behind_to_the_right")
        case .unknown:     return GDLocalizedString("poi.unknown")
        }
    }
}
