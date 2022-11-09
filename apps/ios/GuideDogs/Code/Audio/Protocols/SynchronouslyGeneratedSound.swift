//
//  SynchronouslyGeneratedSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

/// Protocol for sound objects that generate a single audio buffer synchronously (e.g. simple wave files)
protocol SynchronouslyGeneratedSound: Sound {
    
    /// Method for generating the audio buffer for the sound
    func generateBuffer(forLayer: Int) -> AVAudioPCMBuffer?
    
}

extension SynchronouslyGeneratedSound {
    
    /// Default implementation of `nextBuffer()` for sounds that synchronously generate only a single buffer.
    func nextBuffer(forLayer channel: Int) -> Promise<AVAudioPCMBuffer?> {
        // Generate the buffer and immediately resolve the promise.
        return Promise { $0(generateBuffer(forLayer: channel)) }
    }
    
}
