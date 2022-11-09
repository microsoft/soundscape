//
//  LayeredSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

class LayeredSound: Sound {
    var type: SoundType
    
    let description: String
    
    let layeredSounds: [Sound]
    
    let layerCount: Int
    
    init?(_ layeredSounds: Sound...) {
        guard layeredSounds.count > 0 else {
            return nil
        }
        
        self.layeredSounds = layeredSounds
        layerCount = layeredSounds.count
        
        // All sub-sounds must have only a single channel
        guard layeredSounds.allSatisfy({ $0.layerCount == 1 }) else {
            return nil
        }
        
        // All sub-sounds must have analogous sound types
        let type = layeredSounds[0].type
        let typesMatch = layeredSounds.allSatisfy({ channel in
            switch (channel.type, type) {
            case (.standard, .standard),
                 (.localized, .localized),
                 (.relative, .relative),
                 (.compass, .compass):
                return true
            default:
                return false
            }
        })
        
        guard typesMatch else {
            return nil
        }
        
        self.type = type
        
        if let first = layeredSounds.first?.description {
            description = "[\(layeredSounds[layeredSounds.startIndex + 1 ..< layeredSounds.endIndex].reduce(first) { $0 + ", " + $1.description })]"
        } else {
            description = "[]"
        }
    }
    
    func nextBuffer(forLayer index: Int) -> Promise<AVAudioPCMBuffer?> {
        guard index < layerCount else {
            return Promise<AVAudioPCMBuffer?> { $0(nil) }
        }
        
        return layeredSounds[index].nextBuffer(forLayer: 0)
    }
}

extension LayeredSound: SoundBase {
    /// Looks up the optional equalizer parameters for a given layer
    func equalizerParams(for layerIndex: Int) -> EQParameters? {
        guard layerIndex < layerCount else {
            return nil
        }
        
        return layeredSounds[layerIndex].equalizerParams(for: 0)
    }
}
