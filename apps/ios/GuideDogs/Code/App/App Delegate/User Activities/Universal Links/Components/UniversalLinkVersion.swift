//
//  UniversalLinkVersion.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum UniversalLinkVersion: String, Codable {
    
    // `rawValue` should be the version
    // in the universal link URL
    //
    // e.g. "https://soundscape-app.yourservicesdomain.com/<Version>/<Path>?<QueryItems>"
    //
    case v1
    case v2
    case v3
    
    // MARK: Parameters
    
    static func currentVersion(for path: UniversalLinkPath) -> UniversalLinkVersion {
        switch path {
        case .experience: return v3
        case .shareMarker: return v1
        }
    }
    
    // `defaultVersion` is used when Soundscape
    // is launched with an unversioned universal link
    static let defaultVersion: UniversalLinkVersion = .v1
    
}
