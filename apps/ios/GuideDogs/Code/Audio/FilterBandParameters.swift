//
//  FilterParameters.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

struct FilterBandParameters: Decodable {
    /// The bandwidth of the EQ filter, in octaves.
    let bandwidth: Float
    
    /// The bypass state of the EQ filter band.
    let bypass: Bool
    
    /// The EQ filter type.
    let filterType: AVAudioUnitEQFilterType
    
    /// The frequency of the EQ filter, in hertz.
    let frequency: Float
    
    /// The gain of the EQ filter, in decibels.
    let gain: Float
    
    enum CodingKeys: String, CodingKey {
        case bandwidth
        case bypass
        case filterType
        case frequency
        case gain
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bandwidth = try values.decode(Float.self, forKey: .bandwidth)
        bypass = try values.decode(Bool.self, forKey: .bypass)
        frequency = try values.decode(Float.self, forKey: .frequency)
        gain = try values.decode(Float.self, forKey: .gain)
        filterType = try .named(try values.decode(String.self, forKey: .filterType))
    }
    
    init(bandwidth: Float, bypass: Bool, filterType: AVAudioUnitEQFilterType, frequency: Float, gain: Float) {
        self.bandwidth = bandwidth
        self.bypass = bypass
        self.filterType = filterType
        self.frequency = frequency
        self.gain = gain
    }
}

enum AVAudioUnitEQFilterTypeDecodingError: Error {
    case invalidFilterName
}

private extension AVAudioUnitEQFilterType {
    static func named(_ name: String) throws -> AVAudioUnitEQFilterType {
        switch name {
        case "parametric": return .parametric
        case "lowPass": return .lowPass
        case "highPass": return .highPass
        case "resonantLowPass": return .resonantLowPass
        case "resonantHighPass": return .resonantHighPass
        case "bandPass": return .bandPass
        case "bandStop": return .bandStop
        case "lowShelf": return .lowShelf
        case "highShelf": return .highShelf
        case "resonantLowShelf": return .resonantLowShelf
        case "resonantHighShelf": return .resonantHighShelf
        default: throw AVAudioUnitEQFilterTypeDecodingError.invalidFilterName
        }
    }
}
