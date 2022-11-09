//
//  Character+Extension.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Character {
    
    /// Determine if a character is a digit.
    ///
    /// Example:
    ///
    ///     let char = Character("3")
    ///     let isDigit = char.isDigit()
    ///     print(isDigit)
    ///     // Prints "true"
    ///
    /// - Returns: `true` if the character is a valid digit, `false` otherwise.
    func isDigit() -> Bool {
        return CharacterSet.decimalDigits.contains(self.unicodeScalar)
    }
    
    /// Determine if a character is a whitespace or a newline.
    ///
    /// Example:
    ///
    ///     let char = Character(" ")
    ///     let isWhitespaceOrNewline = char.isWhitespaceOrNewline()
    ///     print(isWhitespaceOrNewline)
    ///     // Prints "true"
    ///
    /// - Returns: `true` if the character is a whitespace or a newline, `false` otherwise.
    func isWhitespaceOrNewline() -> Bool {
        return CharacterSet.whitespacesAndNewlines.contains(self.unicodeScalar)
    }
    
    /// Returns the `UnicodeScalar` value of the character.
    var unicodeScalar: UnicodeScalar {
        let string = String(self).unicodeScalars
        return string[string.startIndex]
    }
}
