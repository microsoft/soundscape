//
//  Int+Extension.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Int {
    
    /// Transforms an integer into a spelled out string.
    ///
    /// Example:
    ///
    ///     let integer = 3
    ///     let locale = Locale(identifier: "en")
    ///     let spelledOut = integer.spelledOut(withLocale: locale)
    ///     print(spelledOut)
    ///     // Prints "three"
    ///
    /// - Parameter locale: A locale object for the spell out text.
    ///   If nil is passed, the current locale  will be used.
    /// - Returns: The spelled out string of the integer.
    func spelledOut(withLocale locale: Locale?) -> String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .spellOut
        if let locale = locale {
            numberFormatter.locale = locale
        }
        
        return numberFormatter.string(from: NSNumber(value: self))
    }
}
