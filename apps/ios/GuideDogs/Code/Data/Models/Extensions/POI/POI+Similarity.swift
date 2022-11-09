//
//  POI+Similarity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension POI {
    
    func match<T: POI>(others: [T], threshold: Double = 1.0) -> T? {
        // Compute weighted similarity matrix
        let weightedMatches = others.compactMap({ (entity) -> (entity: T, metric: Double)? in
            guard isCategoryMatch(other: entity) else {
                return nil
            }
            
            // Similarity metrics will be between (-Inf, 1)
            let stringMetric = computeString(other: entity)
            let spatialMetric = computeSpatial(other: entity)
            
            // `spatialWeight` will be between (0, 1)
            let spatialWeight = max(stringMetric, 0.0)
            let weighted = stringMetric + ( spatialMetric * spatialWeight )
            
            guard weighted > threshold else {
                return nil
            }
            
            return (entity, weighted)
        })
        
        return weightedMatches.max(by: { $0.metric < $1.metric })?.entity
    }
    
    private func isCategoryMatch(other: POI) -> Bool {
        if let filterableA = self as? Typeable, let filterableB = other as? Typeable {
            let isTransitStopA = filterableA.isOfType(SecondaryType.transitStop)
            let isTransitStopB = filterableB.isOfType(SecondaryType.transitStop)
            
            // If one of the POIs is a transit stop, then
            // the other POI should be a transit stop
            return isTransitStopA == isTransitStopB
        }
        
        // There is no semantic information
        // We will assume a match
        return true
    }
    
    private func computeSpatial(other: POI, threshold: CLLocationDistance = 250.0) -> Double {
        // Create `CLLocation` at the center of each entity
        let centerA = CLLocation(latitude: self.centroidLatitude, longitude: self.centroidLongitude)
        let centerB = CLLocation(latitude: other.centroidLatitude, longitude: other.centroidLongitude)
        
        // For each entity, calculate distance as distance from the first entity
        // to the center of the second entity
        let distA = self.distanceToClosestLocation(from: centerB, useEntranceIfAvailable: false)
        let distB = other.distanceToClosestLocation(from: centerA, useEntranceIfAvailable: false)
        
        // Use minimum distance
        return 1 - ( min(distA, distB) / threshold )
    }
    
    private func computeString(other: POI, threshold: Double = 0.8) -> Double {
        let setMetric = self.name.tokenSet(other: other.name)
        let sortMetric = self.name.tokenSort(other: other.name)
        
        return 1 - ( min(setMetric, sortMetric) / threshold )
    }
    
}
