//
//  RawCourseProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol RawCourseProvider: SensorProvider {
    var courseDelegate: RawCourseProviderDelegate? { get set }
    func startCourseProviderUpdates()
    func stopCourseProviderUpdates()
}
