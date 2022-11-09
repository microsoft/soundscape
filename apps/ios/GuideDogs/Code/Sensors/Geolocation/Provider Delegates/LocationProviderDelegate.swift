//
//  LocationProviderDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol LocationProviderDelegate: AnyObject {
    func locationProvider(_ provider: LocationProvider, didUpdateLocation location: CLLocation?)
}
