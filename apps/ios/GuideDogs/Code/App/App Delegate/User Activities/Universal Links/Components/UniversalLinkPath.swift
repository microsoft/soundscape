//
//  UniversalLinkPath.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum UniversalLinkPath: String {
    
    // `rawValue` should be the path (excluding version)
    // in the universal link URL
    //
    // e.g. "https://soundscape-app.yourservicesdomain.com/<Version>/<Path>?<QueryItems>"
    case experience = "experiences"
    case shareMarker = "sharemarker"
    
}
