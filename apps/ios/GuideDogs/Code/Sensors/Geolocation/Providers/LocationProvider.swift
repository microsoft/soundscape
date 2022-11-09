//
//  LocationProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol LocationProvider: AnyObject, SensorProvider {
    var locationDelegate: LocationProviderDelegate? { get set }
    func startLocationUpdates()
    func stopLocationUpdates()
    func startMonitoringSignificantLocationChanges() -> Bool
    func stopMonitoringSignificantLocationChanges()
}
