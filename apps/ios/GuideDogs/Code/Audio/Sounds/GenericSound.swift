//
//  GenericSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import CoreLocation

enum GenericAudioSource {
    case file(URL)
    case bundle(StaticAudioEngineAsset)
}

/// A simplified `Sound` object for playing simple audio assets in standard 2D audio
class GenericSound: SynchronouslyGeneratedSound {
    let type: SoundType
    
    let source: GenericAudioSource
    
    /// Channel count for the generic sound. `GenericSound`s always have only 1 channel
    let layerCount: Int = 1
    
    private var buffer: AVAudioPCMBuffer?
    
    /// Human-readable description of the sound
    var description: String {
        switch source {
        case .file(let url):
            return "{\(url.lastPathComponent)}"
        case .bundle(let asset):
            return "{\(asset.name)}"
        }
    }
    
    var duration: TimeInterval? {
        guard let buffer = buffer else {
            return nil
        }

        let frames = buffer.frameLength
        let sampleRate = buffer.format.sampleRate
        
        return Double(frames) / sampleRate
    }
    
    /// Initialize a standard 2D sound for an audio asset
    ///
    /// - Parameter asset: Audio asset to load
    init(_ asset: StaticAudioEngineAsset) {
        source = .bundle(asset)
        self.type = .standard
        buffer = asset.load()
    }
    
    /// Initialize a localized 3D sound for an audio asset
    ///
    /// - Parameters:
    ///   - asset: The asset to load
    ///   - at: The GPS location the sound is localized with
    init(_ asset: StaticAudioEngineAsset, at: CLLocation) {
        source = .bundle(asset)
        type = .localized(at, .ring)
        buffer = asset.load()
    }
    
    /// Initialize a relative 3D sound for an audio asset
    ///
    /// - Parameters:
    ///   - asset: The asset to load
    ///   - direction: The relative direction the sound should be localized in (relative to the user)
    init(_ asset: StaticAudioEngineAsset, direction: CLLocationDirection) {
        source = .bundle(asset)
        type = .relative(direction, .ring)
        buffer = asset.load()
    }
    
    /// Initialize a 3D sound in a compass direction for an audio asset
    ///
    /// - Parameters:
    ///   - asset: The asset to load
    ///   - compass: The compass direction the sound should be localized in (relative to the user)
    init(_ asset: StaticAudioEngineAsset, compass: CLLocationDirection) {
        source = .bundle(asset)
        type = .compass(compass, .ring)
        buffer = asset.load()
    }
    
    /// Initialize a standard 2D sound for a downloaded audio file
    ///
    /// - Parameter asset: Audio asset to load
    init(_ file: URL) {
        source = .file(file)
        self.type = .standard
        buffer = file.load()
    }
    
    /// Initialize a localized 3D sound for a downloaded audio file
    ///
    /// - Parameters:
    ///   - asset: The asset to load
    ///   - at: The GPS location the sound is localized with
    init(_ file: URL, at: CLLocation) {
        source = .file(file)
        type = .localized(at, .ring)
        buffer = file.load()
    }
    
    /// Initialize a relative 3D sound for a downloaded audio file
    ///
    /// - Parameters:
    ///   - asset: The asset to load
    ///   - direction: The relative direction the sound should be localized in (relative to the user)
    init(_ file: URL, direction: CLLocationDirection) {
        source = .file(file)
        type = .relative(direction, .ring)
        buffer = file.load()
    }
    
    /// Initialize a 3D sound in a compass direction for a downloaded audio file
    ///
    /// - Parameters:
    ///   - asset: The asset to load
    ///   - compass: The compass direction the sound should be localized in (relative to the user)
    init(_ file: URL, compass: CLLocationDirection) {
        source = .file(file)
        type = .compass(compass, .ring)
        buffer = file.load()
    }
    
    /// Generates the audio buffer for the sound.
    func generateBuffer(forLayer index: Int) -> AVAudioPCMBuffer? {
        guard index == 0 else {
            return nil
        }
        
        let preloaded = buffer
        buffer = nil
        return preloaded
    }
}

extension GenericSound: SoundBase {
    /// Looks up the optional equalizer parameters for a given layer
    func equalizerParams(for layerIndex: Int) -> EQParameters? {
        let gain = SettingsContext.shared.afxGain
        
        guard gain != 0 else {
            return nil
        }
        
        return EQParameters(globalGain: gain, parameters: [])
    }
}

private extension URL {
    func load() -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: self) else {
            return nil
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length)) else {
            return nil
        }
        
        do {
            try file.read(into: buffer)
        } catch {
            return nil
        }
        
        return buffer
    }
}
