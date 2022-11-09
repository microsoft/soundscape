//
//  GeolocationManagerUpdateDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol GeolocationManagerUpdateDelegate: AnyObject {
    func didUpdateLocation(_ location: CLLocation)
}
