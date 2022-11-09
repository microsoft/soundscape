//
//  LastSelectedPredicate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct LastSelectedPredicate: SortPredicate {
    
    func areInIncreasingOrder(_ a: POI, _ b: POI) -> Bool {
        guard let a = a as? SelectablePOI, let b = b as? SelectablePOI else {
            // If these POIs aren't selectable, then by default we assume they are in sorted order
            return true
        }
        
        if let aLastSelectedDate = a.lastSelectedDate, let bLastSelectedDate = b.lastSelectedDate {
            return aLastSelectedDate > bLastSelectedDate
        }
        
        return a.lastSelectedDate != nil
    }
    
}
