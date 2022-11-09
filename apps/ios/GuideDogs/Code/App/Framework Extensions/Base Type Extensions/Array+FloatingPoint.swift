//
//  Array+FloatingPoint.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Array where Element: FloatingPoint {
    
    func sum() -> Element? {
        guard count > 0 else {
            return nil
        }
        
        return reduce(0, +)
    }
    
    func mean() -> Element? {
        guard count > 0 else {
            return nil
        }
        
        guard let sum = sum() else {
            return nil
        }
        
        return sum / Element(count)
    }
    
    func stdev() -> Element? {
        guard count > 0 else {
            return nil
        }
        
        guard let mean = mean() else {
            return nil
        }
        
        let variance = reduce(0, { $0 + ( $1 - mean ) * ( $1 - mean ) })
        return sqrt(variance / Element(count))
    }
    
}
