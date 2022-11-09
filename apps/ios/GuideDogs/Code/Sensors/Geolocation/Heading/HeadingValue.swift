//
//  HeadingValue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct HeadingValue: Equatable {
    
    // MARK: Properties
    
    let value: Double
    let accuracy: Double?
    
    // MARK: Initialization
    
    init(_ value: Double, _ accuracy: Double?) {
        self.value = value
        self.accuracy = accuracy
    }
    
    // MARK: `Equatable`
    
    static func == (lhs: HeadingValue, rhs: HeadingValue) -> Bool {
        return lhs.value == rhs.value && lhs.accuracy == rhs.accuracy
    }
}
