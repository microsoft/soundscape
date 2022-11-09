//
//  RawCourseProviderDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol RawCourseProviderDelegate: AnyObject {
    func courseProvider(_ provider: RawCourseProvider, didUpdateCourse course: HeadingValue?, speed: Double?)
}
