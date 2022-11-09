//
//  BeaconSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation

/// Encapsulates a set of audio assets that are all components in an audio beacon. All
/// assets should have the same format and the same length (i.e. same number of audio
/// frames).
class BeaconSound<T: DynamicAudioEngineAsset>: DynamicSound {
    typealias AssetType = T
    
    let type: SoundType
    
    var description: String {
        return "\(T.self)"
    }
    
    let commonFormat: AVAudioFormat
    
    var layerCount: Int = 1
    
    var introAsset: BeaconAccents?
    var outroAsset: BeaconAccents?
    
    private var assets: [T]
    
    private var buffers: [T: AVAudioPCMBuffer]
    
    private var accentBuffers: [BeaconAccents: AVAudioPCMBuffer]
    
    private var silentBuffer: AVAudioPCMBuffer
    
    /// This is the location that the beacon is being rendered for (e.g. the location of the POI the beacon is set on)
    private let referenceLocation: CLLocation
    
    private init?(_ assets: [T], referenceLocation: CLLocation, type: SoundType, includeStartMelody: Bool, includeEndMelody: Bool) {
        self.assets = assets
        self.type = type
        self.referenceLocation = referenceLocation
        self.accentBuffers = [:]
        
        // Load the assets into buffers (note: all assets should be of the same length)
        buffers = assets.reduce(into: [T: AVAudioPCMBuffer](), { dictionary, asset in
            if let buffer = asset.load() {
                dictionary[asset] = buffer
                
                GDLogAudioVerbose("Loaded \(asset.rawValue) (\(buffer.frameLength) frames)")
            }
        })
        
        // We should have at least one buffer, and we need to ensure we were able to load all the assets
        guard let first = buffers.first?.value, buffers.count == assets.count else {
            return nil
        }
        
        // Make sure we actually have assets and they all have the same format (this reduces to nil if we
        // have no assets or they don't have the same format)
        guard buffers.values.allSatisfy({ $0.format == first.format }) else {
            return nil
        }
        
        commonFormat = first.format
        
        // Create a silent buffer of the same length as the rest of the components. This is for use when the component
        // selector returns nil. Component selectors are allowed to return nil for angles  at which the beacon should be
        // silent (this wasn't allowed in the previous SoundContext, but it is supported in the new AudioEngine).
        guard let buffer = AVAudioPCMBuffer(pcmFormat: first.format, frameCapacity: first.frameCapacity) else {
            return nil
        }
        
        if let channels = buffer.floatChannelData {
            for index in 1 ..< Int(first.format.channelCount) {
                channels[index].assign(repeating: 0.0, count: Int(first.frameLength))
            }
        } else if let channels = buffer.int16ChannelData {
            for index in 1 ..< Int(first.format.channelCount) {
                channels[index].assign(repeating: 0, count: Int(first.frameLength))
            }
        } else if let channels = buffer.int32ChannelData {
            for index in 1 ..< Int(first.format.channelCount) {
                channels[index].assign(repeating: 0, count: Int(first.frameLength))
            }
        }
        
        buffer.frameLength = first.frameLength
        silentBuffer = buffer
        
        // Load the start melody
        if includeStartMelody {
            introAsset = .start
            
            if let start = introAsset?.load() {
                accentBuffers[.start] = start
            }
        }
        
        // Load the end melody
        if includeEndMelody {
            outroAsset = .end
            
            if let end = outroAsset?.load() {
                accentBuffers[.end] = end
            }
        }
        
        // Make sure the start and end buffer formats match the other beacon buffer formats
        guard accentBuffers.values.allSatisfy({ $0.format == buffers.values.first?.format }) else {
            return nil
        }
    }
    
    convenience init?(_ assetType: T.Type, at referenceLocation: CLLocation, isLocalized: Bool = true, includeStartMelody: Bool = false, includeEndMelody: Bool = false) {
        if isLocalized {
            self.init(Array(assetType.allCases),
                      referenceLocation: referenceLocation,
                      type: .localized(referenceLocation, .ring),
                      includeStartMelody: includeStartMelody,
                      includeEndMelody: includeEndMelody)
        } else {
            self.init(Array(assetType.allCases),
                      referenceLocation: referenceLocation,
                      type: .standard,
                      includeStartMelody: includeStartMelody,
                      includeEndMelody: includeEndMelody)
        }
    }
    
    convenience init?(_ assetType: T.Type, at referenceLocation: CLLocation, direction: CLLocationDirection, includeStartMelody: Bool = false, includeEndMelody: Bool = false) {
        self.init(Array(assetType.allCases),
                  referenceLocation: referenceLocation,
                  type: .relative(direction, .ring),
                  includeStartMelody: includeStartMelody,
                  includeEndMelody: includeEndMelody)
    }
    
    convenience init?(_ assetType: T.Type, at referenceLocation: CLLocation, compass: CLLocationDirection, includeStartMelody: Bool = false, includeEndMelody: Bool = false) {
        self.init(Array(assetType.allCases),
                  referenceLocation: referenceLocation,
                  type: .compass(compass, .ring),
                  includeStartMelody: includeStartMelody,
                  includeEndMelody: includeEndMelody)
    }
    
    func asset(for userHeading: CLLocationDirection?, userLocation: CLLocation) -> (asset: T, volume: T.Volume)? {
        return T.selector?(.heading(userHeading, userLocation.bearing(to: referenceLocation)))
    }
    
    func asset(userLocation: CLLocation) -> (asset: T, volume: T.Volume)? {
        return T.selector?(.location(userLocation, referenceLocation))
    }
    
    func buffer(for asset: T?) -> AVAudioPCMBuffer {
        if let asset = asset, let buffer = buffers[asset] {
            return buffer
        } else {
            return silentBuffer
        }
    }
    
    func buffer(for melody: BeaconAccents) -> AVAudioPCMBuffer {
        if let buffer = melody.load() {
            return buffer
        } else {
            return silentBuffer
        }
    }
}

extension BeaconSound: SoundBase {
    /// Looks up the optional equalizer parameters for a given layer
    func equalizerParams(for layerIndex: Int) -> EQParameters? {
        let gain = SettingsContext.shared.beaconGain
        
        guard gain != 0 else {
            return nil
        }
        
        return EQParameters(globalGain: gain, parameters: [])
    }
}
