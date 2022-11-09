//
//  CourseProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol CourseProvider: SensorProvider {
    var courseDelegate: CourseProviderDelegate? { get set }
    func startCourseProviderUpdates()
    func stopCourseProviderUpdates()
}
