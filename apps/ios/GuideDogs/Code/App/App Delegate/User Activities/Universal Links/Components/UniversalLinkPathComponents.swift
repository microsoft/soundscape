//
//  UniversalLinkPathComponents.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct UniversalLinkPathComponents {
    
    // MARK: Parameters
    
    let path: UniversalLinkPath
    let version: UniversalLinkVersion
    
    var versionedPath: String {
        let vRawValue = version.rawValue
        let pRawValue = path.rawValue

         return "/\(vRawValue)/\(pRawValue)"
    }

     // MARK: Initialization
    
    init?(path: String) {
        let pathComponents = path.split(separator: "/", maxSplits: 1)

        if pathComponents.count == 1 {
            // URL path does not include a version
            // Parse path components accordingly
            let pRawValue = String(pathComponents[0])
            
            guard let path = UniversalLinkPath(rawValue: pRawValue) else {
                // Failed to parse `UniversalLinkPath`
                return nil
            }

            // Use the default version
            self.version = UniversalLinkVersion.defaultVersion
            self.path = path
        } else if pathComponents.count == 2 {
            // URL path does includes a version
            // Parse path components accordingly
            let vRawValue = String(pathComponents[0])
            let pRawValue = String(pathComponents[1])

            guard let version = UniversalLinkVersion(rawValue: vRawValue) else {
                // Failed to parse `UniversalLinkVersion`
                return nil
            }

            guard let path = UniversalLinkPath(rawValue: pRawValue) else {
                // Failed to parse `UniversalLinkPath`
                return nil
            }

            self.version = version
            self.path = path
        } else {
            // Failed to parse components
            return nil
        }
    }

     init(path: UniversalLinkPath) {
        self.path = path
        // Use the current version when constructing
        // URLs
        self.version = UniversalLinkVersion.currentVersion(for: path)
    }
    
}
