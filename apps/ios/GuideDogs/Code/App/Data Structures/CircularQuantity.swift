//
//  CircularQuantity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct CircularQuantity {

    // MARK: Properties
    
    let valueInDegrees: Double
    let valueInRadians: Double
    
    // MARK: Initialization
    
    init(valueInDegrees: Double) {
        self.valueInDegrees = valueInDegrees
        self.valueInRadians = valueInDegrees.degreesToRadians
    }
    
    init(valueInRadians: Double) {
        self.valueInDegrees = valueInRadians.radiansToDegrees
        self.valueInRadians = valueInRadians
    }
    
    // MARK: -
    
    func normalized() -> CircularQuantity {
        var constant = 1.0
        
        if abs(valueInDegrees) > 360.0 {
            constant = ceil( abs(valueInDegrees) / 360.0 )
        }
        
        let nValueInDegrees = fmod(valueInDegrees + ( constant * 360.0 ), 360.0)
        return CircularQuantity(valueInDegrees: nValueInDegrees)
    }
    
}

extension CircularQuantity: Comparable {
    
    static func == (lhs: CircularQuantity, rhs: CircularQuantity) -> Bool {
        return lhs.normalized().valueInDegrees == rhs.normalized().valueInDegrees
    }
    
    static func > (lhs: CircularQuantity, rhs: CircularQuantity) -> Bool {
        return lhs.normalized().valueInDegrees > rhs.normalized().valueInDegrees
    }
    
    static func < (lhs: CircularQuantity, rhs: CircularQuantity) -> Bool {
        return lhs.normalized().valueInDegrees < rhs.normalized().valueInDegrees
    }
    
    static func + (lhs: CircularQuantity, rhs: CircularQuantity) -> CircularQuantity {
        let sum = lhs.normalized().valueInDegrees + rhs.normalized().valueInDegrees
        return CircularQuantity(valueInDegrees: sum).normalized()
    }
    
    static func - (lhs: CircularQuantity, rhs: CircularQuantity) -> CircularQuantity {
        let difference = lhs.normalized().valueInDegrees - rhs.normalized().valueInDegrees
        return CircularQuantity(valueInDegrees: difference).normalized()
    }
    
    prefix static func - (value: CircularQuantity) -> CircularQuantity {
        let valueInDegrees = value.valueInDegrees
        return CircularQuantity(valueInDegrees: -valueInDegrees).normalized()
    }
    
}

extension CircularQuantity: CustomStringConvertible {
    
    public var description: String {
        return "\(valueInDegrees)"
    }
    
}
