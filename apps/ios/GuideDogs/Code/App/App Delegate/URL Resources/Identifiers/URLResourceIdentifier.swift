//
//  URLResourceIdentifier.swift
//  Openscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum URLResourceIdentifier: String {
    /*
     Important!
     
     `URLResourceIdentifier` raw value should be the document type identifier and should match the identifier provided in the Info.plist (`Imported Type Identifiers` and `Exported Type Identifiers`)
     */
    case gpx = "com.topografix.gpx"
    case route = "io.openscape.doc"
    case legacy_soundscape_route = "soundscape.doc"
}
