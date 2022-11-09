//
//  GDASpatialDataResultEntity+Typeable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension GDASpatialDataResultEntity: Typeable {
    
    func isOfType(_ type: PrimaryType) -> Bool {
        switch type {
        case .transit: return isOfType(.transitStop)
        }
    }
    
    func isOfType(_ type: SecondaryType) -> Bool {
        switch type {
        case .transitStop: return isTransitStop()
        }
    }
    
    private func isTransitStop() -> Bool {
        guard let category = SuperCategory(rawValue: superCategory) else {
            return false
        }
        
        return category == .mobility && localizedName.lowercased().contains(GDLocalizedString("osm.tag.bus_stop").lowercased())
    }
    
}
