//
//  AddressFormatter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import ContactsUI
import AddressBook
import CoreLocation

/// The `AddressFormatter` class handles international formatting of postal addresses.
/// It is recommended that you create an instance of this class when formatting many postal addresses,
/// and use the instance methods; otherwise use the class methods.
class AddressFormatter {
    
    private let postalAddressFormatter = CNPostalAddressFormatter()
    
    func format(from placemark: CLPlacemark,
                street: Bool = true,
                city: Bool = true,
                state: Bool = true,
                postalCode: Bool = true,
                country: Bool = true,
                isoCountryCode: Bool = true,
                subAdministrativeArea: Bool = true,
                subLocality: Bool = true) -> String? {
        var postalAddress: CNPostalAddress
        
        guard let postalAddressObject = placemark.postalAddress else {
            return nil
            
        }
        postalAddress = postalAddressObject
        
        if !street || !city || !state || !postalCode || !country || !isoCountryCode || !subAdministrativeArea || !subLocality {
            postalAddress = postalAddress.postalAddressWithIncludedItems(street: street,
                                                                         city: city,
                                                                         state: state,
                                                                         postalCode: postalCode,
                                                                         country: country,
                                                                         isoCountryCode: isoCountryCode,
                                                                         subAdministrativeArea: subAdministrativeArea,
                                                                         subLocality: subLocality)
        }

        return postalAddressFormatter.string(from: postalAddress)
    }
    
}

extension CNPostalAddress {
    func postalAddressWithIncludedItems(street: Bool = true,
                                        city: Bool = true,
                                        state: Bool = true,
                                        postalCode: Bool = true,
                                        country: Bool = true,
                                        isoCountryCode: Bool = true,
                                        subAdministrativeArea: Bool = true,
                                        subLocality: Bool = true) -> CNMutablePostalAddress {
        let address = CNMutablePostalAddress()
        
        if street { address.street = self.street }
        if city { address.city = self.city }
        if state { address.state = self.state }
        if postalCode { address.postalCode = self.postalCode }
        if country { address.country = self.country }
        if isoCountryCode { address.isoCountryCode = self.isoCountryCode }
        if subAdministrativeArea { address.subAdministrativeArea = self.subAdministrativeArea }
        if subLocality { address.subLocality = self.subLocality }
        
        return address
    }
}

extension CNPostalAddressFormatter {
    class func postalAddressFromPlacemark(_ placemark: CLPlacemark) -> CNMutablePostalAddress {
        let address = CNMutablePostalAddress()
        
        if let street = placemark.street {
            address.street = street
        }

        if let city = placemark.city {
            address.city = city
        }
        
        if let state = placemark.state {
            address.state = state
        }
        
        if let postalCode = placemark.postalCode {
            address.postalCode = postalCode
        }
        
        if let country = placemark.country {
            address.country = country
        }
        
        if let isoCountryCode = placemark.isoCountryCode {
            address.isoCountryCode = isoCountryCode
        }
        
        if let subAdministrativeArea = placemark.subAdministrativeArea {
            address.subAdministrativeArea = subAdministrativeArea
        }
        
        if let subLocality = placemark.subLocality {
            address.subLocality = subLocality
        }
        
        return address
    }
}

extension CLPlacemark {
    
    var street: String? {
        return self.thoroughfare ?? self.postalAddress?.street
    }
    
    var city: String? {
        return self.locality ?? self.postalAddress?.city
    }
    
    var state: String? {
        return self.administrativeArea ?? self.postalAddress?.state
    }
    
}
