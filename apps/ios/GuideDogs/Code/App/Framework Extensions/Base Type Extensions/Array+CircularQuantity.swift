//
//  Array+CircularQuantity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Array where Element == CircularQuantity {
    
    private var radians: [Double] {
        return compactMap({ return $0.normalized().valueInRadians })
    }
    
    private func xMean() -> Double? {
        guard count > 0 else {
            return nil
        }
        
        return radians.reduce(0, { $0 + cos($1) }) / Double(count)
    }
    
    private func yMean() -> Double? {
        guard count > 0 else {
            return nil
        }
        
        return radians.reduce(0, { $0 + sin($1) }) / Double(count)
    }
    
    // Source: https://en.wikipedia.org/wiki/Mean_of_circular_quantities
    func mean() -> Element? {
        guard count > 0 else {
            return nil
        }
        
        guard let xMean = xMean(), let yMean = yMean() else {
            return nil
        }
        
        let meanInRadians = atan2(yMean, xMean)
        
        return CircularQuantity(valueInRadians: meanInRadians).normalized()
    }
    
    func meanInDegrees() -> Double? {
        return mean()?.valueInDegrees
    }
    
    func meanInRadians() -> Double? {
        return mean()?.valueInRadians
    }
    
    // Source: https://en.wikipedia.org/wiki/Directional_statistics
    func stdev() -> Element? {
        guard count > 0 else {
            return nil
        }
        
        guard let xMean = xMean(), let yMean = yMean() else {
            return nil
        }
        
        let stdevInRadians = sqrt( -2 * log( sqrt( (yMean * yMean) + (xMean * xMean) ) ) )
        
        return CircularQuantity(valueInRadians: stdevInRadians).normalized()
    }
    
    func stdevInDegrees() -> Double? {
        return stdev()?.valueInDegrees
    }
    
    func stdevInRadians() -> Double? {
        return stdev()?.valueInRadians
    }
    
}
