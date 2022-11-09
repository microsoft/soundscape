//
//  ExperimentControl.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct ExperimentConfiguration: Codable {
    /// Unique identifier for this experiment configuration
    let uuid: UUID
    
    /// List of experiment IDs
    let experimentIDs: [UUID]
    
    /// Value in the range [0.0, 1.0] indicating the probability that this list
    /// of experiments is enabled for any given user
    let probability: Float
    
    /// Locales this configuration is available in
    let locales: [Locale]
}
