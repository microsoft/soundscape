//
//  Type.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol Type {
    func matches(poi: POI) -> Bool
}
