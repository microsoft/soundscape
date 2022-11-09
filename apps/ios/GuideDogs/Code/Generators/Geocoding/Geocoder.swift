//
//  Geocoder.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import Contacts

class Geocoder {
    
    // MARK: Properties
    
    private let geocoder: AddressGeocoderProtocol
    private let addressFormatter = AddressFormatter()
    
    // MARK: Initialization
    
    init(geocoder: AddressGeocoderProtocol) {
        self.geocoder = geocoder
    }
    
    private func processPlacemarks(_ placemarks: [CLPlacemark]) -> [GeocodedAddress] {
        var geocodedComponents: [GeocodedAddress] = []
        
        for placemark in placemarks {
            guard let placemarkLocation = placemark.location else { continue }
            guard let placemarkAddress = addressFormatter.format(from: placemark, country: false) else { continue }
            let formattedPlacemarkAddress = placemarkAddress.replacingOccurrences(of: "\n", with: ", ")
            
            let placemarkStreet = placemark.street ?? placemark.subLocality ?? placemark.state ?? placemark.subAdministrativeArea ?? placemark.state ?? ""
            
            let component = GeocodedAddress(name: placemark.name ?? placemarkStreet,
                                            location: placemarkLocation,
                                            addressLine: formattedPlacemarkAddress,
                                            streetName: placemarkStreet,
                                            subThoroughfare: placemark.subThoroughfare)
            geocodedComponents.append(component)
        }
        
        return geocodedComponents
    }
    
    // MARK: Forward Geocoding Methods
    
    func geocodeAddressString(address: String, in region: CLRegion? = nil, completionHandler: @escaping ([GeocodedAddress]?) -> Void) {
        // If we cannot call the geocoding service or the geocoding fails, return nil
        // else, return an array or results
        
        guard AppContext.shared.device.isNetworkConnectionAvailable else {
            // Always call completion handler
            completionHandler(nil)
            return
        }

        // Call geocoding service
        // When input region is `nil` and location services are enabled,
        // the geocoder will use the user's location to pick the best results
        geocoder.geocodeAddressString(address, in: region, preferredLocale: LocalizationContext.currentAppLocale, completionHandler: { [weak self] (results, error) in
            guard error == nil else {
                completionHandler(nil)
                return
            }
            
            guard let results = results else {
                completionHandler(nil)
                return
            }
            
            completionHandler(self?.processPlacemarks(results))
        })
    }
    
    // MARK: Reverse Geocoding Methods
    
    func geocodeLocation(location: CLLocation, completionHandler: @escaping ([GeocodedAddress]?) -> Void) {
        // If we cannot call the geocoding service or the geocoding fails, return nil
        // else, return an array or results
        
        guard AppContext.shared.device.isNetworkConnectionAvailable else {
            // Always call completion handler
            completionHandler(nil)
            return
        }
        
        let timeout = DispatchWorkItem { [weak self] in
            self?.geocoder.cancelGeocode()
            completionHandler(nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: timeout)
        
        // Call geocoding service
        // When input region is `nil` and location services are enabled,
        // the geocoder will use the user's location to pick the best results
        geocoder.reverseGeocodeLocation(location, preferredLocale: LocalizationContext.currentAppLocale, completionHandler: { [weak self] (results, error) in
            timeout.cancel()
            
            guard error == nil else {
                if let error = error as? CLError, error.code == CLError.Code.network {
                    GDATelemetry.track("geocoder.apple.rate_limit_exceeded")
                    GDLogError(.application, "Apple Geocoder rate limit exceeded")
                }
                
                completionHandler(nil)
                return
            }
            
            guard let results = results else {
                completionHandler(nil)
                return
            }
            
            completionHandler(self?.processPlacemarks(results))
        })
    }
}
