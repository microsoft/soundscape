//
//  HeadphoneCalibration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct HeadphoneCalibration {
    
    // MARK: Properties
    
    let value: CircularQuantity
    let accuracy: Double
    let timestamp: Date
    
    var valueInDegrees: Double {
        return value.valueInDegrees
    }
    
    var valueInRadians: Double {
        return value.valueInRadians
    }
    
    // MARK: Initialization
    
    init(value: CircularQuantity, accuracy: Double, timestamp: Date) {
        self.value = value.normalized()
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
    
}
