//
//  Address.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import RealmSwift

class Address: Object {
    
    // MARK: Realm Properties
    
    @objc dynamic var key: String = UUID().uuidString
    @objc dynamic var lastSelectedDate: Date?
    @objc dynamic var name: String = ""
    @objc dynamic var addressLine: String?
    @objc dynamic var streetName: String?
    @objc dynamic var latitude: CLLocationDegrees = 0.0
    @objc dynamic var longitude: CLLocationDegrees = 0.0
    @objc dynamic var centroidLatitude: CLLocationDegrees = 0.0
    @objc dynamic var centroidLongitude: CLLocationDegrees = 0.0
    @objc dynamic var searchString: String?
    
    // MARK: Initialization
    
    convenience init(geocodedAddress: GeocodedAddress, searchString: String? = nil) {
        self.init()
        
        name = geocodedAddress.name
        addressLine = geocodedAddress.addressLine
        streetName = geocodedAddress.streetName
        latitude = geocodedAddress.location.coordinate.latitude
        longitude = geocodedAddress.location.coordinate.longitude
        centroidLatitude = geocodedAddress.location.coordinate.latitude
        centroidLongitude = geocodedAddress.location.coordinate.longitude
        self.searchString = searchString
    }
    
    // MARK: Realm
    
    /// Indicates which property represents the primary key of this object
    override static func primaryKey() -> String {
        return "key"
    }
    
}
