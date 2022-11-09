//
//  UniversalLinkParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol UniversalLinkParameters {
    init?(queryItems: [URLQueryItem])
    var queryItems: [URLQueryItem] { get }
}

extension UniversalLinkParameters {
    
    var percentEncodedQueryItems: [URLQueryItem] {
        var percentEncodedQueryItems: [URLQueryItem] = []
        
        // Encode all non-alphanumeric characters
        let allowedChars = CharacterSet.alphanumerics
        
        for item in queryItems {
            // Manually encode the value of the existing
            // `URLQueryItem`
            let encodedValue = item.value?.addingPercentEncoding(withAllowedCharacters: allowedChars)
            // Append the encoded value
            percentEncodedQueryItems.append(URLQueryItem(name: item.name, value: encodedValue))
        }
        
        return percentEncodedQueryItems
    }
    
}
