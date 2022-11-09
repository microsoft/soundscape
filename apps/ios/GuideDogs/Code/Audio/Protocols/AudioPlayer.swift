//
//  AudioPlayer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation

typealias AudioPlayerIdentifier = UUID

enum AudioPlayerState {
    case notPrepared
    case preparing
    case prepared
}

enum AudioPlayerConnectionState {
    case notConnected
    case unknown
    case connected
}

protocol AudioPlayer {
    /// A unique identifier for the AudioPlayer
    var id: AudioPlayerIdentifier { get }
    
    /// Array of nodes and their associated formats
    var layers: [PreparableAudioLayer] { get }
    
    var sound: SoundBase { get }
    var state: AudioPlayerState { get }
    var isPlaying: Bool { get }
    var is3D: Bool { get }
    var volume: Float { get }
    
    func prepare(engine: AVAudioEngine, completion: ((_ success: Bool) -> Void)?)
    func updateConnectionState(_ state: AudioPlayerConnectionState)
    func play(_ userHeading: Heading?, _ userLocation: CLLocation?) throws
    func resumeIfNecessary() throws -> Bool
    func stop()
}

extension AudioPlayer {
    var is3D: Bool {
        if case .standard = sound.type {
            return false
        } else {
            return true
        }
    }
    
    func play(_ userHeading: Heading? = nil, _ userLocation: CLLocation? = nil) throws {
        try play(userHeading, userLocation)
    }
}
