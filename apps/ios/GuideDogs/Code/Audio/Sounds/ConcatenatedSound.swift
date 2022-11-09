//
//  ConcatenatedSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

class ConcatenatedSound: Sound {
    var type: SoundType
    
    let description: String
    
    let concatenatedSounds: [Sound]
    
    let layerCount: Int = 1
    
    private var currentBufferPromise: Promise<AVAudioPCMBuffer?>?
    private var currentSoundIndex = 0
    
    init?(_ sounds: Sound...) {
        guard sounds.count > 0 else {
            return nil
        }
        
        self.concatenatedSounds = sounds
        
        // All sub-sounds must have only a single channel
        guard sounds.allSatisfy({ $0.layerCount == 1 }) else {
            return nil
        }
        
        // All sub-sounds must have analogous sound types
        let type = sounds[0].type
        let typesMatch = sounds.allSatisfy({ channel in
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
        
        if let first = sounds.first?.description {
            description = "[\(sounds[sounds.startIndex + 1 ..< sounds.endIndex].reduce(first) { $0 + ", " + $1.description })]"
        } else {
            description = "[]"
        }
    }
    
    func nextBuffer(forLayer index: Int) -> Promise<AVAudioPCMBuffer?> {
        guard index == 0 else {
            return Promise<AVAudioPCMBuffer?> { $0(nil) }
        }
        
        return Promise<AVAudioPCMBuffer?>.init { [weak self] (resolver) in
            guard let `self` = self else {
                resolver(nil)
                return
            }
            
            self.nextBufferForCurrentIndex(resolver)
        }
    }
    
    private func nextBufferForCurrentIndex(_ resolver: @escaping Promise<AVAudioPCMBuffer?>.Resolver) {
        currentBufferPromise = concatenatedSounds[currentSoundIndex].nextBuffer(forLayer: 0)
        currentBufferPromise?.then(onResolved: { [weak self] (buffer) in
            if let buffer = buffer {
                resolver(buffer)
                return
            }
            
            guard let `self` = self, self.currentSoundIndex < self.concatenatedSounds.count - 1 else {
                resolver(nil)
                return
            }
            
            // Increment the current sound index and get the first buffer of that sound
            self.currentSoundIndex += 1
            self.currentBufferPromise = self.concatenatedSounds[self.currentSoundIndex].nextBuffer(forLayer: 0)
            self.currentBufferPromise?.then(onResolved: { (nextBuffer) in
                resolver(nextBuffer)
            })
        })
    }
}

extension ConcatenatedSound: SoundBase {
    /// Looks up the optional equalizer parameters for a given layer
    func equalizerParams(for layerIndex: Int) -> EQParameters? {
        guard layerIndex == 0 else {
            return nil
        }
        
        return concatenatedSounds.compactMap({ $0.equalizerParams(for: 0) }).first
    }
}
