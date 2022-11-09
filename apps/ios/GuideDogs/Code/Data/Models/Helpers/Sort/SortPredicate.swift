//
//  SortPrediate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol SortPredicate {
    func areInIncreasingOrder(_ a: POI, _ b: POI) -> Bool
}
