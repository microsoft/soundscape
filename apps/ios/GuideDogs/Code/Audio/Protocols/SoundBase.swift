//
//  SoundBase.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol SoundBase: CustomStringConvertible {
    
    /// Type of the sound. This determines the rendering style of the audio (e.g. if the audio should be
    /// played in 3D and how it's 3D location is computed).
    var type: SoundType { get }
    
    /// The number of layers in this sound
    var layerCount: Int { get }
    
    /// Looks up the optional equalizer parameters for a given layer
    func equalizerParams(for layerIndex: Int) -> EQParameters?
}

extension SoundBase {
    var formattedLog: String {
        switch type {
        case .standard:
            return "\(description) (Standard 2D)"
        case .localized(let location, let style):
            return "\(description) (Style: \(style.formattedLog); Localized at \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)))"
        case .compass(let direction, let style):
            return "\(description) (Style: \(style.formattedLog); Compass direction \(direction.roundToDecimalPlaces(0))°)"
        case .relative(let direction, let style):
            return "\(description) (Style: \(style.formattedLog); Relative at \(direction.roundToDecimalPlaces(0))°)"
        }
    }
}
