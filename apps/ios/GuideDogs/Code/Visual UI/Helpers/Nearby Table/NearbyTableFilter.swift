//
//  NearbyTableFilter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct NearbyTableFilter: Equatable {
    
    // MARK: Static Properties
    
    static var defaultFilter: NearbyTableFilter {
        return NearbyTableFilter(type: nil)
    }
    
    static var defaultFilters: [NearbyTableFilter] {
        return [
            .defaultFilter,
            NearbyTableFilter(type: .transit)
        ]
    }
    
    static var primaryTypeFilters: [NearbyTableFilter] {
        var filters: [NearbyTableFilter] = []
        
        // Add default filter
        // There is no `PrimaryType` filter selected
        filters.append(NearbyTableFilter.defaultFilter)
        
        // Add `PrimaryType` filters
        for type in PrimaryType.allCases {
            filters.append(NearbyTableFilter(type: type))
        }
        
        return filters
    }
    
    // MARK: Instance Properties
    
    let type: PrimaryType?
    let localizedString: String
    let image: UIImage?
    
    // MARK: Initialization
    
    init(type: PrimaryType?) {
        self.type = type
        
        if let type = type {
            switch type {
            case .transit:
                self.localizedString = GDLocalizedString("filter.transit")
                self.image = UIImage(named: "Transit")
            }
        } else {
            // There is no `PrimaryType` filter selected
            self.localizedString = GDLocalizedString("filter.all")
            self.image = UIImage(named: "AllPlaces")
        }
    }
    
    // MARK: Equatable
    
    static func == (lhs: NearbyTableFilter, rhs: NearbyTableFilter) -> Bool {
        return lhs.type == rhs.type
    }
    
}
