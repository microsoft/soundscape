//
//  EnvironmentSettingsProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

protocol EnvironmentSettingsProvider: AnyObject {
    var envRenderingAlgorithm: AVAudio3DMixingRenderingAlgorithm { get set }
    var envRenderingDistance: Double { get set }
    
    var envRenderingReverbEnable: Bool { get set }
    var envRenderingReverbPreset: AVAudioUnitReverbPreset { get set }
    var envRenderingReverbBlend: Float { get set }
    var envRenderingReverbLevel: Float { get set }
    
    var envReverbFilterActive: Bool { get set }
    var envReverbFilterBandwidth: Float { get set }
    var envReverbFilterBypass: Bool { get set }
    var envReverbFilterType: AVAudioUnitEQFilterType { get set }
    var envReverbFilterFrequency: Float { get set }
    var envReverbFilterGain: Float { get set }
}
