//
//  CoordinateParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct CoordinateParameters: Codable {
    
    // MARK: Properties
    
    let latitude: Double
    let longitude: Double
    
}

extension CoordinateParameters: UniversalLinkParameters {
    
    private struct Name {
        static let latitude = "lat"
        static let longitude = "lon"
    }
    
    // MARK: Properties
    
    var queryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        
        // Append latitude
        queryItems.append(URLQueryItem(name: Name.latitude, value: "\(latitude)"))
        // Append longitude
        queryItems.append(URLQueryItem(name: Name.longitude, value: "\(longitude)"))
        
        return queryItems
    }
    
    // MARK: Initialization
    
    init?(queryItems: [URLQueryItem]) {
        guard let latitudeStr = queryItems.first(where: { $0.name == Name.latitude })?.value else {
            return nil
        }
        
        guard let latitude = Double(latitudeStr) else {
            return nil
        }
        
        guard let longitudeStr = queryItems.first(where: { $0.name == Name.longitude })?.value else {
            return nil
        }
        
        guard let longitude = Double(longitudeStr) else {
            return nil
        }
        
        self.latitude = latitude
        self.longitude = longitude
    }
    
}
