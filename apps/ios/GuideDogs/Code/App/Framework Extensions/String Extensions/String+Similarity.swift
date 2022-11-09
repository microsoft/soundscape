//
//  String+Similarity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension String {
    
    private static var whitespace: String {
        return " "
    }
    
    private func tokenize(separatedBy separator: String = String.whitespace) -> Token {
        return Token(string: self.lowercased(), separatedBy: separator)
    }
    
    func tokenSort(other: String) -> Double {
        let tokenA = self.tokenize()
        let tokenB = other.tokenize()
        
        // Compute edit distance between token strings
        return tokenA.tokenizedString.weightedMinimumEditDistance(other: tokenB.tokenizedString)
    }
    
    func tokenSet(other: String) -> Double {
        let tokenA = self.tokenize()
        let tokenB = other.tokenize()
        // Compute intersection of tokens
        let intersection = tokenA.intersection(other: tokenB)
        
        // Compute edit distance between intersection of the token strings and
        // each token strings
        let editDistanceA = intersection.tokenizedString.weightedMinimumEditDistance(other: tokenA.tokenizedString)
        let editDistanceB = intersection.tokenizedString.weightedMinimumEditDistance(other: tokenB.tokenizedString)
        
        // Average edit distance
        return (editDistanceA + editDistanceB) / 2.0
    }
    
    private func weightedMinimumEditDistance(other: String) -> Double {
        let editDistance = self.minimumEditDistance(other: other)
        let maxDistance = max(self.count, other.count)
        
        guard maxDistance > 0, editDistance < maxDistance else {
            return 1.0
        }
        
        return ( Double(editDistance) / Double(maxDistance) )
    }
    
    private func minimumEditDistance(other: String) -> Int {
        let minValue = 0
        let maxValue = Int.max
        
        if self.trimmingCharacters(in: .whitespaces).isEmpty || other.trimmingCharacters(in: .whitespaces).isEmpty {
            // One or both of the comparision strings are empty
            // Do not compute the edit distance
            return maxValue
        }
        
        if self == other {
            return minValue
        }
        
        let m = self.count
        let n = other.count
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for index in 1...m {
            // Distance of any first string to an empty second string
            matrix[index][0] = index
        }
        
        for index in 1...n {
            // Distance of any second string to an empty first string
            matrix[0][index] = index
        }
        
        // Compute the Levenshtein distance
        for (i, selfChar) in self.enumerated() {
            for (j, otherChar) in other.enumerated() {
                if otherChar == selfChar {
                    // Substitution of equal character with cost 0
                    matrix[i + 1][j + 1] = matrix[i][j]
                } else {
                    // Minimum of the cost of insertion, deletion, or substitution
                    // added to the already computed costs in the corresponding cells
                    matrix[i + 1][j + 1] = Swift.min(matrix[i][j] + 1, matrix[i + 1][j] + 1, matrix[i][j + 1] + 1)
                }
            }
        }
        
        return matrix[m][n]
    }
    
}
