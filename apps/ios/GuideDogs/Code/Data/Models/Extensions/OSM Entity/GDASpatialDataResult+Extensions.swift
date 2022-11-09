//
//  GDASpatialDataResult+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import CocoaLumberjackSwift

extension GDASpatialDataResultEntity: SelectablePOI {
    
    func distanceToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDistance {
        if self.contains(location: location.coordinate) {
            return 0
        }
        
        return closestLocation(from: location, useEntranceIfAvailable: useEntranceIfAvailable).distance(from: location)
    }
    
    func bearingToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDirection {
        if self.contains(location: location.coordinate) {
            return 0
        }
        
        return location.bearing(to: closestLocation(from: location, useEntranceIfAvailable: useEntranceIfAvailable))
    }
    
    func closestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocation {
        if useEntranceIfAvailable, let entrance = closestEntrance(from: location) {
            return entrance.closestLocation(from: location)
        } else if let edge = closestEdge(from: location) {
            return edge
        }
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var searchString: String? {
        return nil
    }
    
    /// The localized string key for the entity's name tag
    /// - example: When `nameTag` is `bus_stop`, this will return `osm.tag.bus_stop`
    var nameTagLocalizationKey: String? {
        return nameTag.isEmpty ? nil : "osm.tag.\(nameTag)"
    }
    
    var localizedName: String {
        return localizedName(for: LocalizationContext.currentAppLocale)
    }
    
    private func localizedName(for locale: Locale) -> String {
        let languageCode = locale.languageCode ?? LocalizationContext.developmentLocale.languageCode!
        let name = self.name(for: languageCode)
        let ref = self.ref.isEmpty ? nil : self.ref
        
        guard name != nil || ref != nil else {
            // Entity does not have a name or a ref, try to use it's type.
            guard let nameTagLocalizationKey = nameTagLocalizationKey else {
                DDLogWarn("Entity with key \(key) has no name!")
                return ""
            }
            return GDLocalizedString(nameTagLocalizationKey)
        }
        
        if let name = name {
            // Entity has a name (e.g. "Bay 7 Redmond")
            // If it also has a tag (such as "bus_stop"), make sure the tag's localized string ("Bus Stop") is appended in the name ("Bay 7 Redmond Bus Stop").
            
            // Check if the entity has a key for the localization string (e.g. "osm.tag.bus_stop")
            guard let tagLocalizationKey = nameTagLocalizationKey else { return name }
            
            // Make sure the localized string exists for key
            guard LocalizationContext.localizedStringExists(tagLocalizationKey, locale: locale) else { return name }
            
            // Get the localized string of the tag (e.g. "Bus Stop")
            let localizedTagName = GDLocalizedString(tagLocalizationKey)
            
            // Make sure the name of the entity does not already contain the appeneded tag.
            // For example, for an entity named "Bay 7 Redmond Bus Stop", we should not append the "Bus Stop" tag
            guard !name.contains(localizedTagName) else { return name }
            
            // The name does not contain the tag, append it if possible
            let namedTagLocalizationKey = tagLocalizationKey + ".named" // e.g. "osm.tag.bus_stop.named"
            guard LocalizationContext.localizedStringExists(namedTagLocalizationKey, locale: locale) else { return name }

            return GDLocalizedString(namedTagLocalizationKey, name)
        }
        
        if let ref = ref {
            // Entity has a ref (e.g. "WA 520")
            // If it also has a tag (such as "highway"), make sure the tag's localized string ("Highway") is appended in the name ("Highway WA 520").
            
            guard let tagLocalizationKey = nameTagLocalizationKey else { return ref }
            guard LocalizationContext.localizedStringExists(tagLocalizationKey, locale: locale) else { return ref }
            
            let localizedTagName = GDLocalizedString(tagLocalizationKey)
            
            guard !ref.contains(localizedTagName) else { return ref }
            
            // The name does not contain the tag, append it if possible
            let refedTagLocalizationKey = tagLocalizationKey + ".refed" // e.g. "osm.tag.bus_stop.refed"
            guard LocalizationContext.localizedStringExists(refedTagLocalizationKey, locale: locale) else { return ref }
            
            return GDLocalizedString(refedTagLocalizationKey, ref)
        }
        
        return ""
    }
    
    /// Returns the display name, using the `name` or `names` properties
    private func name(for languageCode: String) -> String? {
        for name in names where name.language == languageCode {
            return name.string
        }
        
        return name.isEmpty ? nil : name
    }
    
}

extension GDASpatialDataResultEntity: Road { }

extension GDASpatialDataResultEntity: Path { }
