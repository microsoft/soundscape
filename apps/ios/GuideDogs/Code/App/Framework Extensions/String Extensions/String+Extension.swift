//
//  String+Extension.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import CocoaLumberjackSwift

extension String {
    
    // MARK: Subscript
    
    /// Accesses a character at the given position.
    ///
    /// Example:
    ///
    ///     let string = "Apple"
    ///     let char = string[4]
    ///     print(char)
    ///     // Prints "e"
    ///
    /// - Parameter offset: A valid index of the string. `i` must be less than `character.count`.
    /// - Returns: The Character at index `i`
    private subscript (offset: Int) -> Character {
        let index = self.index(self.startIndex, offsetBy: offset)
        return self[index]
    }
    
    // MARK: Substring

    func substring(from: Int, to: Int) -> String? {
        guard from < self.count else {
            return nil
        }
        
        guard to < self.count else {
            return nil
        }
        
        guard to - from >= 0 else {
            return nil
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)

        return String(self[startIndex...endIndex])
    }
    
    func substring(from: Int) -> String? {
        let startIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[startIndex...])
    }
    
    func substring(from: Int, length: Int) -> String? {
        return self.substring(from: from, to: from+length-1)
    }

    func substring(to: Int) -> String? {
        let endIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[..<endIndex])
    }
    
    /// Removes substrings that start and end with specific strings
    ///
    /// Example:
    ///
    ///     let string = "School <break time='0s'/> around 150 meters"
    ///     let removed = string.removeSubstring(start: " <", ending: ">")
    ///     print(removed)
    ///     // Prints "School around 150 meters"
    ///
    /// - Parameter start: The start string.
    /// - Parameter end: The end string.
    /// - Returns: String by removing substrings
    func removeOccurrencesOfSubstring(start: String, end: String) -> String {
        var copy = self
        while let range = copy.range(of: start + "[^>]+" + end, options: .regularExpression, range: nil, locale: nil) {
            copy = copy.replacingCharacters(in: range, with: "")
        }
        return copy
    }
    
    func replace(characterSet: CharacterSet, with: Self) -> String {
        let components = self.components(separatedBy: characterSet)
        return components.filter { !$0.isEmpty }.joined(separator: with)
    }
    
    // MARK: Convenience

    /// Replaces every digit in the string with it's spelled out word.
    ///
    /// Example:
    ///
    ///     let string = "Model 371"
    ///     let locale = Locale(identifier: "en")
    ///     let spelledOut = string.spelledOutDigits(withLocale: locale)
    ///     print(spelledOut)
    ///     // Prints "Model three seven one"
    ///
    /// - Parameter locale: A locale object for the spell out text.
    ///   If nil is passed, the current locale  will be used.
    /// - Returns: A string where every digit is replaced with it's spelled out word.
    func stringWithSpelledOutDigits(withLocale locale: Locale?) -> String {
        guard !self.isEmpty else { return String() }
        
        var output = String()
        
        // Loop through the characters, if the char is a digit replace it with the spelled out string
        for (index, char) in self.enumerated() {
            if char.isDigit() {
                guard var spelledOutChar = Int(String(char))?.spelledOut(withLocale: locale) else { continue }
                
                // If the next character is not a whitespace, newline or the last character, add a whitespace
                if index+1 < self.count {
                    let nextChar = self[index+1]
                    if !nextChar.isWhitespaceOrNewline() {
                        spelledOutChar += " "
                    }
                }
                
                output.append(spelledOutChar)
            } else {
                output.append(String(char))
            }
        }
        
        return output
    }

    func accessibilityString() -> String {
        return self.lowercased().replacingOccurrences(of: "callout", with: "call out")
    }
    
    public func urlEncoded(plusForSpace: Bool = true) -> String? {
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: "*-._")
        
        if plusForSpace {
            allowed.addCharacters(in: " ")
        }
        
        var encoded = addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
        
        if plusForSpace {
            encoded = encoded?.replacingOccurrences(of: " ", with: "+")
        }
        
        return encoded
    }
    
    func isGeocoordinate() -> Bool {
        guard !isEmpty else {
            return false
        }
        
        let parts = components(separatedBy: CharacterSet(charactersIn: "(,)")).compactMap { Double($0) }
        
        guard parts.count == 2 else {
            return false
        }
        
        return CLLocationCoordinate2D(latitude: parts[0], longitude: parts[1]).isValidLocationCoordinate
    }
}

// MARK: String Arguments

extension String {
    
    /// Regex pattern to find string arguments ("%@" or "%n$@")
    private static let stringArgumentRegexPattern = #"%@|%(\d+)\$@"#

    /// Returns the number of string arguments ("%@" or "%n$@")
    private var argumentCount: Int {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: String.stringArgumentRegexPattern, options: [])
        } catch {
            return 0
        }
        
        return regex.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: self.count))
    }
    
    /// This initializer removes extra arguments or add missing arguments as "(null)".
    ///
    /// If a string object is initialized with a format and arguments, such as
    /// `init(format: String, arguments: [CVarArg])` and the number of format arguments does
    /// not match the number of the given arguments, it can cause a crash (on devices).
    /// On a simulator, iOS adds "(null)" for every missing argument.
    init(normalizedArgsWithFormat format: String, arguments: [String]) {
        let formatArgCount = format.argumentCount
        
        guard formatArgCount != arguments.count else {
            // Format has the same number of arguments
            self.init(format: format, arguments: arguments)
            return
        }
        
        guard formatArgCount > 0 else {
            // Format does not have arguments
            self.init(format: format)
            return
        }
        
        let preciseArgs: [String]
        
        if formatArgCount < arguments.count {
            // Format has less arguments (need to remove)
            preciseArgs = Array(arguments[0...formatArgCount-1])
        } else {
            // Format has more arguments (need to add)
            preciseArgs = arguments + Array(repeating: "(null)", count: formatArgCount-arguments.count)
        }
        
        DDLogWarn("String format warning: \"\(format)\" has \(formatArgCount) arguments but was passed \(arguments.count)")
        
        self.init(format: format, arguments: preciseArgs)
    }
    
}
