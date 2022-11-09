//
//  CourseProviderDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol CourseProviderDelegate: AnyObject {
    func courseProvider(_ provider: CourseProvider, didUpdateCourse course: HeadingValue?)
}
