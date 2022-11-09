//
//  LocationItemViewAccessibilitySortPriority.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct LocationItemViewAccessibilitySortPriority {
    let rightAccessory: Double
    let leftAccessory: Double
    let name: Double
    let distance: Double
    let address: Double
    
    static var defaultSortPriority: LocationItemViewAccessibilitySortPriority {
        return LocationItemViewAccessibilitySortPriority(rightAccessory: 5, leftAccessory: 4, name: 3, distance: 2, address: 1)
    }
}
