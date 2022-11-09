//
//  DeviceHeadingProviderDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol DeviceHeadingProviderDelegate: AnyObject {
    func deviceHeadingProvider(_ provider: DeviceHeadingProvider, didUpdateDeviceHeading heading: HeadingValue?)
}
