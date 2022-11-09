//
//  Typeable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// `Typeable` defines a set of APIs that a class
// conforming to `POI` must instantiate in order
// to be filtered by type
protocol Typeable {
    func isOfType(_ type: PrimaryType) -> Bool
    func isOfType(_ type: SecondaryType) -> Bool
}
