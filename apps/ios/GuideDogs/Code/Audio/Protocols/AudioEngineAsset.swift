//
//  AudioEngineAsset.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

/// `AudioEngineAsset`s are objects that wrap up all the information needed for loading
/// and playing audio files. Objects that implement this protocol are intended to be enums
/// where each case corresponds to an audio asset and all cases share the same file type.
/// See `StaticAudioEngineAsset.swift`.
protocol AudioEngineAsset: RawRepresentable {
    /// Name of the asset
    var name: String { get }
    
    /// File type of the asset
    var type: String { get }
}

extension AudioEngineAsset where RawValue == String {
    
    // MARK: Asset Name Helper
    
    var name: String {
        return rawValue
    }
    
}

extension AudioEngineAsset {
    
    /// Defaults all audio engine assets to be wav files. If non-wav audio assets are added, they will
    /// need to override this default for the `type` property and possibly also the default implementation
    /// of `load()` to accommodate for their new file format.
    var type: String {
        return "wav"
    }
    
    /// Loads a sound asset from a file in the main bundle into an AVAudioPCMBuffer.
    ///
    /// - Parameters:
    ///   - asset: Name of the sound asset
    ///   - ofType: Extension of the asset file
    /// - Returns: PCM buffer with sound data if the asset could be found and loaded correctly, nil otherwise.
    func load() -> AVAudioPCMBuffer? {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            assertionFailure("Audio asset could not be found (name: \(name), type: \(type))")
            GDLogAudioError("Audio asset could not be found (name: \(name), type: \(type))")
            return nil
        }
        
        guard let url = URL(string: path) else {
            assertionFailure("Audio asset URL not valid (name: \(name), type: \(type))")
            GDLogAudioError("Audio asset URL not valid (name: \(name), type: \(type))")
            return nil
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            
            try file.read(into: buffer)
            
            return buffer
        } catch {
            GDLogAudioError("Audio asset could not be loaded (name: \(name), type: \(type))")
            return nil
        }
    }
}
