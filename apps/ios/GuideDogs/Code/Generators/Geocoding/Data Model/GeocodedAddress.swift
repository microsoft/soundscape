//
//  GeocodedAddress.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

@objcMembers class GeocodedAddress: NSObject {
    
    // MARK: Properties
    
    let name: String
    let location: CLLocation
    let addressLine: String
    let streetName: String
    let subThoroughfare: String?
    
    // MARK: Initialization
    
    init(name: String, location: CLLocation, addressLine: String, streetName: String, subThoroughfare: String?) {
        self.name = name
        self.location = location
        self.addressLine = addressLine
        self.streetName = streetName
        self.subThoroughfare = subThoroughfare
    }
    
}
