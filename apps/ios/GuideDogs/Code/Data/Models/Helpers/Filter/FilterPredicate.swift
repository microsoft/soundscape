//
//  FilterPredicate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol FilterPredicate {
    func isIncluded(_ a: POI) -> Bool
}

extension FilterPredicate {
    
    func invert() -> FilterPredicate {
        return CompoundPredicate(notPredicateWithSubpredicate: self)
    }
    
}
