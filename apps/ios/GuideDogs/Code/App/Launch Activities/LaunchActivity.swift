//
//  LaunchActivity.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum LaunchActivity: Int, CaseIterable {
    ///
    /// `RawValue` determines which activity to attempt if multiple
    /// activites are scheduled at app launch
    ///
    case reviewApp
    case shareApp
}
