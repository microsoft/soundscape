//
//  LocationItemStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum LocationItemStyle {
    
    case plain
    case inset
    case addWaypoint(index: Int?)
    case editWaypoint(index: Int)
    
    var configuration: AnyLocationItemStyleConfiguration {
        switch self {
        case .plain:
            return PlainLocationItemStyleConfiguration().wrapper
        case .inset:
            return InsetLocationItemStyleConfiguration().wrapper
        case .addWaypoint(let index):
            if let index = index {
                return AddWaypointExistingItemStyleConfiguration(index: index).wrapper
            } else {
                return AddWaypointNewItemStyleConfiguration().wrapper
            }
        case .editWaypoint(let index):
            return EditWaypointItemStyleConfiguration(index: index).wrapper
        }
    }
    
}
