//
//  CompoundFilterPredicate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct CompoundPredicate: FilterPredicate {
    
    private enum Operator {
        case not
        case and
        case or
    }
    
    // MARK: Properties
    
    private let subpredicates: [FilterPredicate]
    private let `operator`: Operator
    
    // MARK: Initialization
    
    init(notPredicateWithSubpredicate predicate: FilterPredicate) {
        self.subpredicates = [predicate]
        self.operator = .not
    }
    
    init(andPredicatesWithSubpredicates predicates: [FilterPredicate]) {
        self.subpredicates = predicates
        self.operator = .and
    }
    
    init(orPredicateWithSubpredicates predicates: [FilterPredicate]) {
        self.subpredicates = predicates
        self.operator = .or
    }
    
    // MARK: Filtering
    
    func isIncluded(_ a: POI) -> Bool {
        switch `operator` {
        case .not: return notIsIncluded(a, predicates: subpredicates)
        case .and: return andIsIncluded(a, predicates: subpredicates)
        case .or: return orIsIncluded(a, predicates: subpredicates)
        }
    }
    
    private func notIsIncluded(_ a: POI, predicates: [FilterPredicate]) -> Bool {
        guard let predicate = predicates.first else {
            return false
        }
        
        return predicate.isIncluded(a) == false
    }
    
    private func andIsIncluded(_ a: POI, predicates: [FilterPredicate]) -> Bool {
        for predicate in predicates {
            guard predicate.isIncluded(a) else {
                return false
            }
        }
        
        // All of the predicates evaluated true
        return true
    }
    
    private func orIsIncluded(_ a: POI, predicates: [FilterPredicate]) -> Bool {
        return predicates.contains(where: { $0.isIncluded(a) })
    }
    
}
