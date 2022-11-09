//
//  ServiceModelProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol OSMServiceModelProtocol {
    // MARK: Type Alias
    typealias TileDataLookupCallback = (HTTPStatusCode, TileData?, Error?) -> Void
    typealias DynamicDataLookupCallback = (HTTPStatusCode, String?, Error?) -> Void
    
    // MARK: Functions
    func getTileDataWithQueue(tile: VectorTile, categories: SuperCategories, queue: DispatchQueue, callback: @escaping TileDataLookupCallback)
    func getDynamicData(dynamicURL: String, callback: @escaping DynamicDataLookupCallback)
}

extension OSMServiceModelProtocol {
    
    func getTileData(tile: VectorTile, categories: SuperCategories, queue: DispatchQueue = DispatchQueue.main, callback: @escaping TileDataLookupCallback) {
        getTileDataWithQueue(tile: tile, categories: categories, queue: queue, callback: callback)
    }
}
