//
//  DynamicAudioPlayer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation
import Combine

protocol FinishableAudioPlayerDelegate: AnyObject {
    func onPlayerFinished(_ playerId: AudioPlayerIdentifier)
}

protocol FinishableAudioPlayer {
    var delegate: FinishableAudioPlayerDelegate? { get set }
    
    func finish()
}

class DynamicAudioPlayer<T: DynamicSound>: AudioPlayer {
    
    // MARK: AudioPlayer Protocol
    
    let id = AudioPlayerIdentifier()
    
    var layers: [PreparableAudioLayer] {
        return [layer]
    }
    
    private var layer: PreparableAudioLayer
    
    var volume: Float {
        get {
            return layer.volume
        }
        set {
            layer.volume = newValue * SettingsContext.shared.beaconVolume
        }
    }
    
    weak var delegate: FinishableAudioPlayerDelegate?
    
    // MARK: Sound
    
    let sound: SoundBase
    
    private(set) var state: AudioPlayerState = .notPrepared
    
    private(set) var isPlaying: Bool = false
    
    private(set) var connectionState: AudioPlayerConnectionState = .notConnected
    
    // MARK: Queue
    
    private weak var queue: DispatchQueue!
    
    // MARK: 3D Audio Properties
    
    private var userHeading: Heading?
    
    private(set) var userLocation: CLLocation?
    
    private var isDimmed: Bool = false
    
    private var observer: NSObjectProtocol?
    
    private var cancellables: [AnyCancellable] = []
    
    // MARK: Asset Buffers
    
    private var currentAsset: T.AssetType?
    
    private var introFrameLength: AVAudioFrameCount = 0
    
    private var isFinishing: Bool = false
        
    init?(sound: T, queue: DispatchQueue) {
        self.queue = queue
        self.sound = sound
        layer = PreparableAudioLayer(eqParameters: sound.equalizerParams(for: 0))
        layer.format = sound.commonFormat
        
        cancellables.append(NotificationCenter.default.publisher(for: .beaconVolumeChanged).sink { [weak self] _ in
            self?.layer.volume = SettingsContext.shared.beaconVolume
        })
        
        cancellables.append(NotificationCenter.default.publisher(for: .beaconGainChanged).sink { [weak self] _ in
            self?.layer.globalGain = SettingsContext.shared.beaconGain
        })
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        layer.disconnect()
        layer.detach()
    }
    
    func prepare(engine: AVAudioEngine, completion: ((_ success: Bool) -> Void)?) {
        // Continuous audio players load synchronously, so they skip the `.preparing` state and go directly to `.prepared`
        layer.attach(to: engine)
        state = .prepared
        
        // Set up the listener for location updates if the sound is localized
        if case .localized = sound.type {
            observer = NotificationCenter.default.addObserver(forName: Notification.Name.locationUpdated, object: nil, queue: nil) { [weak self] (notification) in
                guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
                    return
                }
                
                self?.update(location)
            }
        } else if ProximityBeacon.self == T.AssetType.self {
            observer = NotificationCenter.default.addObserver(forName: Notification.Name.locationUpdated, object: nil, queue: nil) { [weak self] (notification) in
                guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
                    return
                }
                
                self?.update(location)
            }
        }
        
        completion?(true)
    }
    
    func updateConnectionState(_ state: AudioPlayerConnectionState) {
        connectionState = state
    }
    
    func play(_ userHeading: Heading? = nil, _ userLocation: CLLocation? = nil) throws {
        assert(state == .prepared, "You must call .prepare() before .play()!")
        
        guard state == .prepared else {
            GDLogAudioError("The player must be prepared before it can be played!")
            return
        }
        
        if isPlaying {
            stop()
        }
        
        // Schedule the intro asset if one exists
        scheduleIntroAsset()
        
        if let location = userLocation {
            update(location)
        }
        
        self.userHeading = userHeading
        
        userHeading?.onHeadingDidUpdate { [weak self] (heading) in
            guard let `self` = self else {
                return
            }
            
            self.update(heading?.value)
            
            if !self.isPlaying {
                do {
                    try self.play()
                } catch {
                    GDLogAudioError("Exception: \((error as NSError).localizedFailureReason ?? error.localizedDescription)")
                    GDATelemetry.track("audio_engine.exception", with: [
                        "description": error.localizedDescription,
                        "location": "DynamicAudioPlayer.swift:onHeadingDidUpdate()"
                    ])
                }
            }
        }
        
        update(userHeading?.value)
        try play()
    }
    
    private func play() throws {
        guard state == .prepared else {
            GDLogAudioError("The player must be prepared before it can be played!")
            return
        }
        
        try self.layer.play()
        isPlaying = true
    }
    
    func resumeIfNecessary() throws -> Bool {
        var resumed = false
        
        // Resume playback if the player has isPlaying set to true but the node is stopped
        if isPlaying && !layer.isPlaying {
            scheduleAsset(currentAsset)
            try self.layer.play()
            resumed = true
        }
        
        return resumed
    }
    
    func stop() {
        userHeading = nil
        
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
            observer = nil
        }
        
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard self.isPlaying else {
                return
            }
            
            self.layer.stop()
            
            self.state = .notPrepared
            
            self.layer.disconnect()
            self.layer.detach()
            
            self.isPlaying = false
            self.currentAsset = nil
        }
    }
    
    private func update(_ userLocation: CLLocation) {
        self.userLocation = userLocation
        
        if case .localized(let audioLocation, _) = sound.type {
            // If we don't have a heading, then dim the audio
            if isDimmed {
                layer.position = AVAudio3DPoint(from: userLocation.bearing(to: audioLocation), distance: 5.0)
            } else {
                layer.position = AVAudio3DPoint(from: userLocation.bearing(to: audioLocation), distance: DebugSettingsContext.shared.envRenderingDistance)
            }
        }
        
        // If this player's sound varies it's asset based on user location, then we need to update the dynamic asset
        guard let sound = sound as? T else {
            return
        }
        
        guard let dynamicAsset = sound.asset(userLocation: userLocation) else {
            return
        }
        
        volume = dynamicAsset.volume
        
        guard dynamicAsset.asset != currentAsset else {
            return
        }
        
        scheduleAsset(dynamicAsset.asset)
    }
    
    private func update(_ userHeading: CLLocationDirection?) {
        guard let userLocation = self.userLocation else {
            return
        }
        
        guard let sound = sound as? T else {
            return
        }
        
        // Update the dimming state of the audio
        if userHeading == nil {
            GDLogAudioVerbose("\(sound.description) dimmed == true")
            isDimmed = true
            update(userLocation)
        } else if isDimmed {
            GDLogAudioVerbose("\(sound.description) dimmed == false")
            isDimmed = false
            update(userLocation)
        }
        
        guard let dynamicAsset = sound.asset(for: userHeading, userLocation: userLocation) else {
            return
        }
        
        volume = dynamicAsset.volume
        
        guard dynamicAsset.asset != currentAsset else {
            return
        }
        
        scheduleAsset(dynamicAsset.asset)
    }
    
    private func scheduleIntroAsset() {
        guard !isFinishing else {
            return
        }
        
        guard let sound = sound as? T, let intro = sound.introAsset else {
            return
        }
        
        let buffer = sound.buffer(for: intro)
        
        // Keep track of the frame length for later use and then schedule the buffer
        introFrameLength = buffer.frameLength
        layer.player.scheduleBuffer(buffer, at: nil, options: [.interrupts])
    }
    
    private func scheduleAsset(_ newAsset: T.AssetType?) {
        guard !isFinishing else {
            return
        }
        
        defer {
            currentAsset = newAsset
        }
        
        guard let sound = sound as? T else {
            return
        }
        
        let buffer = sound.buffer(for: newAsset)
        
        guard T.AssetType.beatsInPhrase > 0, let lastRendered = layer.player.lastRenderTime, (lastRendered.isHostTimeValid || lastRendered.isSampleTimeValid) else {
            // If we don't have a last rendered time, just play the buffer after the intro ends
            let time = AVAudioTime(sampleTime: AVAudioFramePosition(introFrameLength), atRate: buffer.format.sampleRate)
            layer.player.scheduleBuffer(buffer, at: time, options: [.interrupts, .loops])
            return
        }
        
        guard let playerTime = layer.player.playerTime(forNodeTime: lastRendered) else {
            // If we don't have a last rendered time, just play the buffer after the intro ends
            let time = AVAudioTime(sampleTime: AVAudioFramePosition(introFrameLength), atRate: buffer.format.sampleRate)
            layer.player.scheduleBuffer(buffer, at: time, options: [.interrupts, .loops])
            return
        }
        
        guard playerTime.sampleTime > introFrameLength else {
            // If there is an intro and it's not done playing yet, then just schedule the buffer to play after it ends
            let time = AVAudioTime(sampleTime: AVAudioFramePosition(introFrameLength), atRate: buffer.format.sampleRate)
            layer.player.scheduleBuffer(buffer, at: time, options: [.interrupts, .loops])
            return
        }
        
        // Schedule the buffer to start playing on the next beat
        let samplesPerBeat = Int64(sound.buffer(for: currentAsset).frameLength) / Int64(T.AssetType.beatsInPhrase)
        let beatsPlayed = (playerTime.sampleTime - Int64(introFrameLength)) / samplesPerBeat
        let startTime = (beatsPlayed + 1) * samplesPerBeat + Int64(introFrameLength)
        
        // Clip the buffer to start at the right beat
        let beatInPhrase = beatsPlayed % Int64(T.AssetType.beatsInPhrase)
        guard let partialBuffer = buffer.suffix(from: Int((beatInPhrase + 1) * samplesPerBeat)) else {
            // If we don't have a last rendered time, just play the buffer now
            layer.player.scheduleBuffer(buffer, at: AVAudioTime(sampleTime: startTime, atRate: playerTime.sampleRate), options: [.interrupts, .loops])
            return
        }
        
        // Schedule the buffers
        layer.player.scheduleBuffer(partialBuffer, at: AVAudioTime(sampleTime: startTime, atRate: playerTime.sampleRate), options: [.interrupts])
        layer.player.scheduleBuffer(buffer, at: AVAudioTime(sampleTime: startTime + Int64(partialBuffer.frameLength), atRate: playerTime.sampleRate), options: [.loops])
    }
}

extension DynamicAudioPlayer: FinishableAudioPlayer {
    func finish() {
        isFinishing = true
        
        guard let sound = sound as? T, let outro = sound.outroAsset else {
            delegate?.onPlayerFinished(id)
            return
        }
        
        let buffer = sound.buffer(for: outro)
        
        guard T.AssetType.beatsInPhrase > 0, let lastRendered = layer.player.lastRenderTime, (lastRendered.isHostTimeValid || lastRendered.isSampleTimeValid) else {
            // If we don't have a last rendered time, just finish immediately without playing the outro
            delegate?.onPlayerFinished(id)
            return
        }
        
        guard let playerTime = layer.player.playerTime(forNodeTime: lastRendered) else {
            // If we can't get a player time, just finish immediately without playing the outro
            delegate?.onPlayerFinished(id)
            return
        }
        
        // Schedule the buffer to start playing on the next beat
        let samplesPerBeat = Int64(sound.buffer(for: currentAsset).frameLength) / Int64(T.AssetType.beatsInPhrase)
        let beatsPlayed = (playerTime.sampleTime - Int64(introFrameLength)) / samplesPerBeat
        let startTime = (beatsPlayed + 1) * samplesPerBeat + Int64(introFrameLength)
        
        // Schedule the outro buffer
        let start = AVAudioTime(sampleTime: startTime, atRate: playerTime.sampleRate)
        layer.player.scheduleBuffer(buffer, at: start, options: [.interrupts], completionCallbackType: .dataPlayedBack) { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.queue.async {
                self.delegate?.onPlayerFinished(self.id)
            }
        }
    }
}

fileprivate extension AVAudioPCMBuffer {
    func suffix(from: Int) -> AVAudioPCMBuffer? {
        guard Int(frameLength) > from else {
            return nil
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: self.format, frameCapacity: frameLength - UInt32(from)) else {
            return nil
        }
        
        // Currently only supports float formatted audio buffers with a single channel... Expand later
        guard let newChannel = buffer.floatChannelData?[0], let oldChannel = floatChannelData?[0] else {
            return nil
        }
        
        // Copy over all the frames
        for (newIndex, oldIndex) in (from ..< Int(frameLength)).enumerated() {
            newChannel[newIndex] = oldChannel[oldIndex]
        }
        
        buffer.frameLength = buffer.frameCapacity
        
        return buffer
    }
}
