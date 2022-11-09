//
//  POI+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// MARK: Realm Keys

struct POIKeys {
    static let lastSelectedDate = "lastSelectedDate"
}

extension POI {
    typealias Keys = POIKeys
    
    func isEqual(_ poi: POI) -> Bool {
        return self.key == poi.key
    }
}
