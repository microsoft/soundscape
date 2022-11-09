//
//  StringDebug.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct StringDebugOptions: OptionSet {
    let rawValue: Int
    
    static let doubleLength = StringDebugOptions(rawValue: 1 << 0)
    static let accented     = StringDebugOptions(rawValue: 1 << 1)
    static let bounded      = StringDebugOptions(rawValue: 1 << 2)
    static let rightToLeft  = StringDebugOptions(rawValue: 1 << 3)
}

// MARK: String Debug Helpers

extension String {
    func transform(with options: StringDebugOptions) -> String {
        guard !options.isEmpty else {
            return self
        }
        
        var string = self
        
        // "String" -> "S̈t̃r̀i̥ñģ"
        if options.contains(.accented) {
            string = string.accented()
        }
        
        // "S̈t̃r̀i̥ñģ" -> "S̈t̃r̀i̥ñģ S̈t̃r̀i̥ñģ"
        if options.contains(.doubleLength) {
            string = string.doubleLength()
        }
        
        // "S̈t̃r̀i̥ñģ S̈t̃r̀i̥ñģ" -> "ģñi̥r̀t̃S̈ ģñi̥r̀t̃S̈"
        if options.contains(.rightToLeft) {
            string = string.rightToLeft()
        }
        
        // "ģñi̥r̀t̃S̈ ģñi̥r̀t̃S̈" -> "[# ģñi̥r̀t̃S̈ ģñi̥r̀t̃S̈ #]"
        if options.contains(.bounded) {
            string = string.bounded()
        }
        
        return string
    }
    
    private static let latinLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    private static let latinLettersAccentuated = "ÄB̀ÇD̃E̥F̊G̈H̀I̧J̃K̥L̊M̈ǸO̧P̃Q̥R̊S̈T̀U̧ṼW̥X̊ŸZ̀a̧b̃c̥d̊ëf̀ģh̃i̥j̊k̈l̀m̧ño̥p̊q̈r̀şt̃u̥v̊ẅx̀y̧z̃"
    private static let latinLettersAccentMap = Dictionary(uniqueKeysWithValues: zip(latinLetters, latinLettersAccentuated))
    
    /// Returns the accentuated version of the string, i.e. "String" -> "S̈t̃r̀i̥ñģ".
    /// - Note: Currently, accentuation only supports latin characters, any other characters will remain the same.
    private func accented() -> String {
        return String(self.map { String.latinLettersAccentMap[$0] ?? $0 })
    }
    
    /// "String" -> "String String"
    private func doubleLength() -> String {
        return "\(self) \(self)"
    }
    
    /// "String" -> "gnirtS".
    private func rightToLeft() -> String {
        return String(self.reversed())
    }
    
    /// "[# String #]"
    private func bounded() -> String {
        return "[# \(self) #]"
    }
}

// MARK: String Debug Launch Arguments

extension ProcessInfo {
    private struct LocalizedStringsLaunchArguments {
        /// Return all localized strings in double length, i.e. "String" -> "String String".
        static let doubleLength = "NSDoubleLocalizedStrings"
        
        /// Return all localized strings accented, i.e. "String" -> "S̈t̃r̀i̥ñģ".
        static let accented = "NSAccentuateLocalizedStrings"
        
        /// Return all localized strings bounded, i.e. "String" -> "[# String #]".
        static let bounded = "NSSurroundLocalizedStrings"
        
        /// Return all localized strings reversed, i.e. "String" -> "gnirtS".
        static let rightToLeft = "NSForceRightToLeftLocalizedStrings"
    }
    
    var stringDebugOptions: StringDebugOptions {
        var options: StringDebugOptions = []
        
        if arguments.contains("-" + LocalizedStringsLaunchArguments.doubleLength) {
            options.insert(.doubleLength)
        }
        
        if arguments.contains("-" + LocalizedStringsLaunchArguments.accented) {
            options.insert(.accented)
        }
        
        if arguments.contains("-" + LocalizedStringsLaunchArguments.bounded) {
            options.insert(.bounded)
        }
        
        if arguments.contains("-" + LocalizedStringsLaunchArguments.rightToLeft) {
            options.insert(.rightToLeft)
        }
        
        return options
    }
}
