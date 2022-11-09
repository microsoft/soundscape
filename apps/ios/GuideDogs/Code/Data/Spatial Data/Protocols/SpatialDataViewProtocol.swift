//
//  SpatialDataViewProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol SpatialDataViewProtocol {
    var pois: [POI] { get }
    var markedPoints: [ReferenceEntity] { get }
    var intersections: [Intersection] { get }
    var roads: [Road] { get }
    
    func getEntities(categories: [String]?, maxItems: Int, sortByDistance: Bool) -> [POI]
}

extension SpatialDataViewProtocol {
    /// Wraps `getEntities(...)` with default parameter values
    ///
    /// - Parameters:
    ///   - superCategory: Super categories to include
    ///   - maxItems: Maximum number of entities to return
    ///   - reorderByDistance: If true, the returned list will be sorted by distance (instead of priority then distance)
    /// - Returns: An array of POIs
    func getEntities(categories: [String]?, maxItems: Int, sortByDistance: Bool = false) -> [POI] {
        return getEntities(categories: categories, maxItems: maxItems, sortByDistance: sortByDistance)
    }
}
