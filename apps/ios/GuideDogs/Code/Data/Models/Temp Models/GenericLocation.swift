//
//  GenericLocation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// Generic Location POIs act as the underlying POI for a ReferenceEntity that doesn't
/// refer to any of the other standard POI types (GDASpatialDataResultEntity or Address).
/// This is used for POIs that were created based on the user's current location.
class GenericLocation: SelectablePOI {
    
    // MARK: Properties
    
    var key: String
    
    var lastSelectedDate: Date?
    
    var name: String
    
    var localizedName: String {
        return name
    }
    
    var superCategory: String = SuperCategory.places.rawValue
    var amenity: String! = "custom location"
    
    var phone: String?
    var addressLine: String?
    var streetName: String?
    var searchString: String?
    
    var dynamicURL: String?
    
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    
    var centroidLatitude: CLLocationDegrees {
        get {
            return latitude
        }
        set {
            latitude = newValue
        }
    }
    
    var centroidLongitude: CLLocationDegrees {
        get {
            return longitude
        }
        set {
            longitude = newValue
        }
    }
    
    var coordinates: [Any]?
    var entrances: [POI]?
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: Initialization

    init(ref: ReferenceEntity) {
        key = ref.id
        name = ref.nickname ?? ref.estimatedAddress ?? ""
        
        lastSelectedDate = ref.lastSelectedDate
        
        latitude = ref.latitude
        longitude = ref.longitude
        
        addressLine = ref.estimatedAddress
    }
    
    init(lat: CLLocationDegrees, lon: CLLocationDegrees, name nickname: String = "", address: String? = nil) {
        key = UUID().uuidString
        name = nickname
        
        lastSelectedDate = Date()
        
        latitude = lat
        longitude = lon
        addressLine = address
    }
    
    // MARK: Methods

    func contains(location: CLLocationCoordinate2D) -> Bool {
        return location == self.location.coordinate
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
