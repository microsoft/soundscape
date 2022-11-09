//
//  POISearchProviderProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol POISearchProviderProtocol {
    var providerName: String { get }
    
    func search(byKey: String) -> POI?
    
    func objects(predicate: NSPredicate) -> [POI]
}
