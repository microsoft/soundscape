//
//  Address+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Address: SelectablePOI {
    
    var localizedName: String {
        return name
    }
    
    var superCategory: String {
        return SuperCategory.places.rawValue
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var coordinates: [Any]? {
        return nil
    }
    
    var entrances: [POI]? {
        return nil
    }
    
    func contains(location: CLLocationCoordinate2D) -> Bool {
        return self.location.coordinate.latitude == location.latitude && self.location.coordinate.longitude == location.longitude
    }
    
    func updateDistanceAndBearing(with location: CLLocation) {
        assert(false, "`updateDistanceAndBearing(with location:)` is missing implementation")
        
        // no-op
        return
    }
    
    func distanceToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDistance {
        return self.location.distance(from: location)
    }
    
    func bearingToClosestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocationDirection {
        return location.bearing(to: self.location)
    }
    
    func closestLocation(from location: CLLocation, useEntranceIfAvailable: Bool) -> CLLocation {
        return self.location
    }
    
}

extension Address {
    
    static func addressContainsStreet(address: String, streetName: String) -> Bool {
        let addressNorm = LanguageFormatter.expandCodedDirection(for: address).lowercasedWithAppLocale()
        let streetNameNorm = PostalAbbreviations.format(streetName, locale: LocalizationContext.currentAppLocale).lowercasedWithAppLocale()

        return addressNorm.contains(streetNameNorm)
    }
    
}
