//
//  RouteParameters+Codable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension RouteParameters {
    
    // MARK: Decoding
    
    static func decode(_ data: Data) -> RouteParameters? {
        let decoder = JSONDecoder()

        guard let parameters = try? decoder.decode(RouteParameters.self, from: data) else {
            GDLogURLResourceError("Failed to decode")
            return nil
        }
        
        return parameters
    }
    
    static func decode(from url: URL) -> RouteParameters? {
        defer {
            // Remove document from cache
            try? FileManager.default.removeItem(at: url)
        }
        
        guard let data = try? Data(contentsOf: url) else {
            GDLogURLResourceError("Failed to decode - Failed to fetch data from file URL")
            return nil
        }
        
        return decode(data)
    }
    
    // MARK: Encoding
    
    static func encode(_ parameters: RouteParameters) -> Data? {
        let encoder = JSONEncoder()
        
        return try? encoder.encode(parameters)
    }
    
    static func encode(from route: Route, context: RouteParameters.Context) -> Data? {
        guard let parameters = RouteParameters(route: route, context: context) else {
            GDLogURLResourceError("Failed to encode - Failed to initialize parameters")
            return nil
        }
        
        return encode(parameters)
    }
    
    static func encode(from detail: RouteDetail, context: RouteParameters.Context) -> Data? {
        guard case .database(let id) = detail.source else {
            GDLogURLResourceError("Encoding is only supported for Realm routes")
            return nil
        }
        
        guard let route = SpatialDataCache.routeByKey(id) else {
            GDLogURLResourceError("Failed to encode - Failed to fetch route from Realm")
            return nil
        }
        
        return encode(from: route, context: context)
    }
    
    // MARK: File URLs
    
    private static func writeToTemporaryFile(_ data: Data?) -> URL? {
        guard let data = data else {
            GDLogURLResourceError("Encoded data is `nil`")
            return nil
        }
        
        // Save file to temporary directory using a localized filename
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).soundscape")
        
        do {
            try data.write(to: url)
            return url
        } catch {
            GDLogURLResourceError("Failed to write encoded route to file")
            return nil
        }
    }
    
    static func encodeAndWriteToTemporaryFile(_ parameters: RouteParameters) -> URL? {
        return writeToTemporaryFile(encode(parameters))
    }
    
    static func encodeAndWriteToTemporaryFile(from route: Route, context: RouteParameters.Context) -> URL? {
        return writeToTemporaryFile(encode(from: route, context: context))
    }
    
    static func encodeAndWriteToTemporaryFile(from detail: RouteDetail, context: RouteParameters.Context) -> URL? {
        return writeToTemporaryFile(encode(from: detail, context: context))
    }
    
}
