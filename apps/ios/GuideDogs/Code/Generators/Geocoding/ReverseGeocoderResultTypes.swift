//
//  ReverseGeocoderResultTypes.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let estimatedAddressDidComplete = Notification.Name("EstimatedAddressDidComplete")
}

protocol ReverseGeocoderResult {
    var location: CLLocation { get }
    var heading: Heading { get }
    var time: Date { get }
    
    func buildCallout(origin: CalloutOrigin, sound playModeSound: Bool, useClosestRoadIfAvailable: Bool) -> CalloutProtocol
    func isSignificantlyDifferent(_ rhs: ReverseGeocoderResult) -> Bool
}

struct GenericGeocoderResult: ReverseGeocoderResult {
    /// Location that was reverse geocoded
    let location: CLLocation
    
    /// The heading the user was facing when this geocoder result was generated
    let heading: Heading
    
    /// Time the location was reverse geocoded
    let time: Date = Date()
    
    /// Key of the road that was selected by the reverse geocoder (this could be different
    /// from the `closestRoadKey` due to sticky road logic)
    let roadKey: String?
    
    /// Location of the closest point along the road corresponding to the `roadKey` property.
    let roadLocation: CLLocation?
    
    /// Key of the road that was nearest to the reverse geocoded location
    let closestRoadKey: String?
    
    /// Location of the closest point along the road corresponding to the `closestRoadKey` property.
    let closestRoadLocation: CLLocation?
    
    /// POI containing the reverse geocoded location. This POI may be a marker - this should
    /// be checked before using the POI directly.
    let poiKey: String?
    
    /// If `poiKey` is non-nil, this flag indicates if the POI was the current destination
    /// at the time the location was reverse geocoded. If `poiKey` is nil, this flag has
    /// no meaning.
    let wasDestination: Bool
    
    // MARK: Computed Properties
    
    var road: Road? {
        guard let key = roadKey else {
            return nil
        }
        
        return SpatialDataCache.searchByKey(key: key) as? Road
    }
    
    var closestRoad: Road? {
        guard let key = closestRoadKey else {
            return nil
        }
        
        return SpatialDataCache.searchByKey(key: key) as? Road
    }
    
    var poi: POI? {
        guard let key = poiKey else {
            return nil
        }
        
        return SpatialDataCache.searchByKey(key: key)
    }
    
    // MARK: Methods
    
    init(location loc: CLLocation,
         heading originalHeading: Heading,
         roadKey road: String? = nil,
         roadLocation roadLoc: CLLocation? = nil,
         closestRoadKey closest: String? = nil,
         closestRoadLocation closestLoc: CLLocation? = nil,
         poiKey poi: String? = nil,
         wasDestination destination: Bool = false) {
        location = loc
        heading = originalHeading
        roadKey = road
        roadLocation = roadLoc
        closestRoadKey = closest
        closestRoadLocation = closestLoc
        poiKey = poi
        wasDestination = destination
    }
    
    func buildCallout(origin: CalloutOrigin, sound playModeSound: Bool, useClosestRoadIfAvailable: Bool) -> CalloutProtocol {
        return LocationCallout(origin, geocodedResult: self, sound: playModeSound, useClosest: useClosestRoadIfAvailable)
    }
    
    func getRoadCalloutComponents(fromLocation: CLLocation? = nil, useClosest useClosestRoadIfAvailable: Bool = false, useOriginalHeading: Bool = false) -> LocationCalloutComponents? {
        let location = fromLocation ?? self.location
        
        guard let road = useClosestRoadIfAvailable ? closestRoad : road else {
            return nil
        }
        
        guard let roadLocation = useClosestRoadIfAvailable ? closestRoadLocation : roadLocation else {
            return nil
        }
        
        let encoded = useOriginalHeading ?
            LanguageFormatter.encodedDirection(fromLocation: location, toLocation: roadLocation, heading: heading.value ?? Heading.defaultValue) :
            LanguageFormatter.encodedDirection(toLocation: roadLocation)
        
        return LocationCalloutComponents(name: road.localizedName,
                                         location: roadLocation,
                                         distance: location.distance(from: roadLocation),
                                         encodedDirection: encoded,
                                         bearing: location.bearing(to: roadLocation))
    }
    
    func getPOICalloutComponents(fromLocation: CLLocation? = nil, useOriginalHeading: Bool = false) -> LocationCalloutComponents? {
        let location = fromLocation ?? self.location
        
        guard let poi = poi else {
            return nil
        }
        
        let poiLocation = poi.closestLocation(from: location)
        
        let encoded = useOriginalHeading ?
            LanguageFormatter.encodedDirection(fromLocation: location, toLocation: poiLocation, heading: heading.value ?? Heading.defaultValue) :
            LanguageFormatter.encodedDirection(toLocation: poiLocation)
        
        return LocationCalloutComponents(name: poi.localizedName,
                                         location: poiLocation,
                                         distance: poi.distanceToClosestLocation(from: location),
                                         encodedDirection: encoded,
                                         bearing: location.bearing(to: poiLocation))
    }
    
    func isSignificantlyDifferent(_ rhs: ReverseGeocoderResult) -> Bool {
        guard let rhs = rhs as? GenericGeocoderResult else {
            return true
        }
        
        return roadKey != rhs.roadKey || poiKey != rhs.poiKey
    }
}

struct InsideGeocoderResult: ReverseGeocoderResult {
    /// Location that was reverse geocoded
    let location: CLLocation
    
    /// The heading the user was facing when this geocoder result was generated
    let heading: Heading
    
    /// Time the location was reverse geocoded
    let time: Date = Date()
    
    /// POI containing the reverse geocoded location. This POI may be a marker - this should
    /// be checked before using the POI directly.
    let poiKey: String
    
    /// This flag indicates if the POI was the current destination at the time the location
    /// was reverse geocoded.
    let wasDestination: Bool
    
    // MARK: Computed Properties
    
    var poi: POI? {
        return SpatialDataCache.searchByKey(key: poiKey)
    }
    
    // MARK: Methods
    
    init(location loc: CLLocation,
         heading originalHeading: Heading,
         key: String,
         wasDestination destination: Bool = false) {
        location = loc
        heading = originalHeading
        poiKey = key
        wasDestination = destination
    }
    
    func buildCallout(origin: CalloutOrigin, sound playModeSound: Bool, useClosestRoadIfAvailable: Bool) -> CalloutProtocol {
        // This method ignores the `useClosestRoadIfAvailable` parameter
        return InsideLocationCallout(origin, geocodedResult: self, sound: playModeSound)
    }
    
    func getCalloutComponents() -> LocationCalloutComponents? {
        guard let poi = poi else {
            return nil
        }
        
        // Note that we always return a distance of 0.0 and no encoded direction since the callout was generated within the location
        return LocationCalloutComponents(name: poi.localizedName,
                                         location: poi.closestLocation(from: location),
                                         distance: 0.0,
                                         encodedDirection: "",
                                         bearing: location.bearing(to: poi.closestLocation(from: location)))
    }
    
    func isSignificantlyDifferent(_ rhs: ReverseGeocoderResult) -> Bool {
        guard let rhs = rhs as? InsideGeocoderResult else {
            return true
        }
        
        return poiKey != rhs.poiKey
    }
}

class AlongsideGeocoderResult: ReverseGeocoderResult {
    /// Location that was reverse geocoded
    let location: CLLocation
    
    /// The heading the user was facing when this geocoder result was generated
    let heading: Heading
    
    /// Time the location was reverse geocoded
    let time: Date = Date()
    
    /// Key of the road that was selected by the reverse geocoder (this could be different
    /// from the `closestRoadKey` due to sticky road logic)
    let roadKey: String
    
    /// Location of the closest point along the road corresponding to the `roadKey` property.
    let roadLocation: CLLocation
    
    /// Key of the road that was nearest to the reverse geocoded location
    let closestRoadKey: String
    
    /// Location of the closest point along the road corresponding to the `closestRoadKey` property.
    let closestRoadLocation: CLLocation
    
    /// Key of the intersection that was nearest to the reverse geocoded location
    let intersectionKey: String?
    
    // Estimated address of the user's location
    var estimatedAddress: GeocodedAddress?
    
    // MARK: Computed Properties
    
    var road: Road? {
        return SpatialDataCache.searchByKey(key: roadKey) as? Road
    }
    
    var closestRoad: Road? {
        return SpatialDataCache.searchByKey(key: closestRoadKey) as? Road
    }
    
    var intersection: Intersection? {
        guard let key = intersectionKey else {
            return nil
        }
        
        return SpatialDataCache.intersectionByKey(key)
    }
    
    // MARK: Methods
    
    init(location loc: CLLocation,
         heading originalHeading: Heading,
         roadKey road: String,
         roadLocation roadLoc: CLLocation,
         closestRoadKey closest: String,
         closestRoadLocation closestLoc: CLLocation,
         intersectionKey intersection: String?) {
        location = loc
        heading = originalHeading
        roadKey = road
        roadLocation = roadLoc
        closestRoadKey  = closest
        closestRoadLocation = closestLoc
        intersectionKey = intersection
        
        SpatialDataCache.fetchEstimatedAddress(location: location) { (address) in
            self.estimatedAddress = address
            NotificationCenter.default.post(name: Notification.Name.estimatedAddressDidComplete, object: self)
        }
    }
    
    func buildCallout(origin: CalloutOrigin, sound playModeSound: Bool, useClosestRoadIfAvailable: Bool) -> CalloutProtocol {
        return AlongRoadLocationCallout(origin, geocodedResult: self, sound: playModeSound, useClosest: useClosestRoadIfAvailable)
    }
    
    func getRoadCalloutComponents(fromLocation: CLLocation? = nil, useClosest useClosestRoadIfAvailable: Bool = false, useOriginalHeading: Bool = false) -> LocationCalloutComponents? {
        let location = fromLocation ?? self.location
        
        guard let road = useClosestRoadIfAvailable ? closestRoad : road else {
            return nil
        }
        
        let roadLocation = useClosestRoadIfAvailable ? closestRoadLocation : self.roadLocation
        
        let encoded = useOriginalHeading ?
            LanguageFormatter.encodedDirection(fromLocation: location, toLocation: roadLocation, heading: heading.value ?? Heading.defaultValue) :
            LanguageFormatter.encodedDirection(toLocation: roadLocation)
        
        return LocationCalloutComponents(name: road.localizedName,
                                         location: roadLocation,
                                         distance: location.distance(from: roadLocation),
                                         encodedDirection: encoded,
                                         bearing: location.bearing(to: roadLocation))
    }
    
    func getIntersectionCalloutComponents(fromLocation: CLLocation? = nil, useClosest useClosestRoadIfAvailable: Bool = false, useOriginalHeading: Bool = false) -> LocationCalloutComponents? {
        let location = fromLocation ?? self.location
        
        guard let intersection = intersection else {
            return nil
        }
        
        let encoded = useOriginalHeading ?
            LanguageFormatter.encodedDirection(fromLocation: location, toLocation: intersection.location, heading: heading.value ?? Heading.defaultValue) :
            LanguageFormatter.encodedDirection(toLocation: intersection.location)
        
        let localizedName: String
        if let road = useClosestRoadIfAvailable ? closestRoad : road {
            localizedName = intersection.localizedName(excluding: road.localizedName)
        } else {
            localizedName = intersection.localizedName
        }
        
        return LocationCalloutComponents(name: localizedName,
                                         location: intersection.location,
                                         distance: location.distance(from: intersection.location),
                                         encodedDirection: encoded,
                                         bearing: location.bearing(to: intersection.location))
    }
    
    func isSignificantlyDifferent(_ rhs: ReverseGeocoderResult) -> Bool {
        guard let rhs = rhs as? AlongsideGeocoderResult else {
            return true
        }
        
        guard let road = road, let rhsRoad = rhs.road else {
            return true
        }
        
        // We use road names to compare different roads, as road IDs are not reliable
        // because a road can be composed of multiple sections with different IDs.
        return road.localizedName != rhsRoad.localizedName
    }
}
