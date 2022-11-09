//
//  SuperCategoryPredicate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct SuperCategoryPredicate: FilterPredicate {
    
    let expectedSuperCategory: SuperCategory
    
    init(expected: SuperCategory) {
        self.expectedSuperCategory = expected
    }
    
    func isIncluded(_ a: POI) -> Bool {
        guard let category = SuperCategory(rawValue: a.superCategory) else {
            return false
        }
        
        return category == expectedSuperCategory
    }
    
}
