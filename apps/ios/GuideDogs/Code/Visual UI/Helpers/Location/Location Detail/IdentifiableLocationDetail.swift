//
//  IdentifiableLocationDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/*
 * Wraps `LocationDetail` such that it can be used in a SwiftUI
 * `List` view
 */
class IdentifiableLocationDetail: Identifiable {
    
    // MARK: Properties
    
    let id = UUID()
    let locationDetail: LocationDetail
    var index: Int?
    
    // MARK: Initialization
    
    init(locationDetail: LocationDetail, index: Int? = nil) {
        self.locationDetail = locationDetail
        self.index = index
    }
    
}
