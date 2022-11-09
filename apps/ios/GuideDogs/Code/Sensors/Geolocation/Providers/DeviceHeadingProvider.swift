//
//  DeviceHeadingProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol DeviceHeadingProvider: AnyObject, SensorProvider {
    var headingDelegate: DeviceHeadingProviderDelegate? { get set }
    func startDeviceHeadingUpdates()
    func stopDeviceHeadingUpdates()
}
