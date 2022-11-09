//
//  Sound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

/// Protocol for sound objects that describes how a sound should be rendered, provides the audio buffers
/// for the sound, and provides a human-readable description of the sound for logging purposes.
protocol Sound: SoundBase {
    
    /// A method for generating the next PCM audio buffer for this sound. This method allows for
    /// asynchronous buffer generation.
    func nextBuffer(forLayer: Int) -> Promise<AVAudioPCMBuffer?>
    
}
