//
//  EntityParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct EntityParameters: Codable {
    
    enum Source: Int, Codable {
        case osm
    }
    
    // MARK: Properties
    
    let source: Source
    let lookupInformation: String
    
}

extension EntityParameters: UniversalLinkParameters {
    
    private struct Name {
        static let source = "source"
        
        static func lookupInformation(for source: Source) -> String {
            switch source {
            case .osm: return "id"
            }
        }
    }
    
    // MARK: Properties
    
    var queryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        
        // Append `source`
        queryItems.append(URLQueryItem(name: Name.source, value: "\(source.rawValue)"))
        
        // Append `lookupInformation`
        let name = Name.lookupInformation(for: source)
        queryItems.append(URLQueryItem(name: name, value: lookupInformation))
        
        return queryItems
    }
    
    // MARK: Initialization
    
    init?(queryItems: [URLQueryItem]) {
        guard let sString = queryItems.first(where: { $0.name == Name.source })?.value else {
            return nil
        }
        
        guard let sRawValue = Int(sString) else {
            return nil
        }
        
        guard let source = Source(rawValue: sRawValue) else {
            return nil
        }
        
        let name = Name.lookupInformation(for: source)
        
        guard let lookupInformation = queryItems.first(where: { $0.name == name })?.value else {
            return nil
        }
        
        self.source = source
        self.lookupInformation = lookupInformation
    }
    
}
