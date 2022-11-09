//
//  PostalAbbreviations.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CocoaLumberjackSwift

/// Postal abbreviations can be found here:
/// https://wiki.openstreetmap.org/wiki/Name_finder:Abbreviations
class PostalAbbreviations {
    
    private static var abbreviationsCache = [Locale: [String: String]]()
    
    fileprivate static func abbreviations(with locale: Locale) -> [String: String]? {
        if let abbreviations = abbreviationsCache[locale] {
            return abbreviations
        }
        guard let languageCode = locale.languageCode else { return nil }
        guard let filePath = Bundle.main.path(forResource: "StreetSuffixAbbreviations_\(languageCode)", ofType: "plist") else { return nil }
        guard let abbreviations = NSDictionary(contentsOfFile: filePath) as? [String: String] else { return nil }
        
        abbreviationsCache[locale] = abbreviations
        
        return abbreviations
    }
    
    /// Replace all postal abbreviations in a string
    class func format(_ string: String, locale: Locale = Locale.init(identifier: "en")) -> String {
        guard !string.isEmpty else {
            return string
        }
        
        let string = PostalAbbreviations.expandSaintAbbreviation(string, locale: locale)
        
        let words = string.components(separatedBy: " ")
        var processed = [String]()
        
        for word in words {
            processed.append(PostalAbbreviations.expandAbbreviation(word, locale: locale))
        }
        
        return processed.joined(separator: " ")
    }
    
    /// Replace string as postal abbreviation if needed

    private class func expandAbbreviation(_ string: String, locale: Locale = Locale(identifier: "en")) -> String {
        guard let expansions = PostalAbbreviations.abbreviations(with: locale) else {
            DDLogWarn("Postal abbreviations file not found for locale \"\(locale.identifier)\"")
            return string
        }
        
        var expansionKey = string.uppercased(with: locale).replacingOccurrences(of: ".", with: "")
        let endsWithComma = expansionKey.hasSuffix(",")
        
        if endsWithComma {
            expansionKey = expansionKey.replacingOccurrences(of: ",", with: "")
        }
        
        if let expansion = expansions[expansionKey]?.lowercased(with: locale) {
            return endsWithComma ? expansion + "," : expansion
        } else {
            return string
        }
    }
    
    /// Expands "St" and "St." to "Saint" if it is the first word in a string
    private class func expandSaintAbbreviation(_ string: String, locale: Locale) -> String {
        guard !string.isEmpty else {
            return string
        }
        
        let lowercased = string.lowercased(with: locale)
        
        if lowercased.hasPrefix("st. ") || lowercased == "st." {
            return "Saint" + string.dropFirst(3)
        }
        
        if lowercased.hasPrefix("st ") || lowercased == "st" {
            return "Saint" + string.dropFirst(2)
        }
        
        return string
    }
    
}
