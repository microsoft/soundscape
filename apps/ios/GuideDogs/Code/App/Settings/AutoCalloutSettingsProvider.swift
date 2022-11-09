//
//  AutoCalloutSettingsProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol AutoCalloutSettingsProvider: AnyObject {
    var automaticCalloutsEnabled: Bool { get set }
    var placeSenseEnabled: Bool { get set }
    var landmarkSenseEnabled: Bool { get set }
    var mobilitySenseEnabled: Bool { get set }
    var informationSenseEnabled: Bool { get set }
    var safetySenseEnabled: Bool { get set }
    var intersectionSenseEnabled: Bool { get set }
    var destinationSenseEnabled: Bool { get set }
}
