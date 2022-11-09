//
//  Locatable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

protocol Locatable {
    var location: CLLocation { get }
}
