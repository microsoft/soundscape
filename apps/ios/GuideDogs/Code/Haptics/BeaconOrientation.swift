//
//  BeaconOrientation.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

/// Private implementation of an orientable for building the beacon feedback
class BeaconOrientation: Orientable {
    var bearing: CLLocationDirection {
        return userLocation.bearing(to: beaconLocation)
    }
    
    private let beaconLocation: CLLocation
    private var userLocation: CLLocation
    private var locationCancellable: AnyCancellable?
    
    init?(_ beacon: CLLocation) {
        guard let loc = AppContext.shared.geolocationManager.location else {
            return nil
        }
        
        userLocation = loc
        beaconLocation = beacon
        
        locationCancellable = NotificationCenter.default.publisher(for: .locationUpdated).sink { [weak self] _ in
            guard let loc = AppContext.shared.geolocationManager.location else {
                return
            }
            
            self?.userLocation = loc
        }
    }
    
    deinit {
        locationCancellable?.cancel()
        locationCancellable = nil
    }
}
