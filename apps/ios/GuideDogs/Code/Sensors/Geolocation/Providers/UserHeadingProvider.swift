//
//  UserHeadingProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol UserHeadingProvider: AnyObject, SensorProvider {
    var headingDelegate: UserHeadingProviderDelegate? { get set }
    var accuracy: Double { get }
    func startUserHeadingUpdates()
    func stopUserHeadingUpdates()
}
