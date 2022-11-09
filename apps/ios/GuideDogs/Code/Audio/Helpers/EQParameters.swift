//
//  EQParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

struct EQParameters: Decodable {
    /// Array of filter parameters for each band in the filter
    let bandParameters: [FilterBandParameters]
    
    /// The overall gain adjustment applied to the signal, in decibels. The default value is 0 db. The valid range of values is -96 db to 24 db.
    let globalGain: Float
    
    init(globalGain: Float = 0.0, parameters: [FilterBandParameters]) {
        self.globalGain = max(-96.0, min(24.0, globalGain))
        self.bandParameters = parameters
    }
}
