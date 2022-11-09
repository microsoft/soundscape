//
//  PreparableAudioLayer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

class PreparableAudioLayer {
    weak var engine: AVAudioEngine?
    
    let player: AVAudioPlayerNode = .init()
    private let equalizer: AVAudioUnitEQ?
    private let mixer: AVAudioMixerNode?
    
    var format: AVAudioFormat?
    
    var volume: Float = 1.0 {
        didSet {
            player.volume = volume
            mixer?.outputVolume = volume
        }
    }
    
    var globalGain: Float? {
        get {
            return equalizer?.globalGain
        }
        
        set {
            if let value = newValue {
                equalizer?.globalGain = max(-96.0, min(24.0, value))
            }
        }
    }
    
    var position: AVAudio3DPoint {
        get {
            return mixer?.position ?? player.position
        }
        set {
            if let mixer = mixer {
                mixer.position = newValue
            } else {
                player.position = newValue
            }
        }
    }
    
    var isAttached: Bool {
        return engine != nil
    }
    
    var isPlaying: Bool {
        return player.isPlaying
    }
    
    init(eqParameters: EQParameters? = nil) {
        // Create and configure the EQ node if necessary
        guard let eqParameters = eqParameters else {
            equalizer = nil
            mixer = nil
            configure()
            return
        }
        
        equalizer = AVAudioUnitEQ(numberOfBands: eqParameters.bandParameters.count)
        equalizer?.globalGain = eqParameters.globalGain
        
        mixer = AVAudioMixerNode()
        
        for index in 0 ..< eqParameters.bandParameters.count {
            let band = equalizer?.bands[index]
            let bandParameters = eqParameters.bandParameters[index]
            
            band?.bandwidth = bandParameters.bandwidth
            band?.bypass = bandParameters.bypass
            band?.filterType = bandParameters.filterType
            band?.frequency = bandParameters.frequency
            band?.gain = bandParameters.gain
        }
        
        configure()
    }
    
    private func configure() {
        player.volume = 1.0
        
        if let mixer = mixer {
            mixer.renderingAlgorithm = DebugSettingsContext.shared.envRenderingAlgorithm
            mixer.reverbBlend = DebugSettingsContext.shared.envRenderingReverbBlend
        } else {
            player.renderingAlgorithm = DebugSettingsContext.shared.envRenderingAlgorithm
            player.reverbBlend = DebugSettingsContext.shared.envRenderingReverbBlend
        }
    }
    
    func attach(to engine: AVAudioEngine) {
        self.engine = engine
        
        engine.attach(player)
        
        if let equalizer = equalizer, let mixer = mixer {
            engine.attach(equalizer)
            engine.attach(mixer)
        }
    }
    
    func connect(to node: AVAudioNode) {
        guard let engine = engine else {
            GDLogAudioError("Attempted to connect to a node when not attached to an audio engine!")
            return
        }
        
        guard let equalizer = equalizer, let mixer = mixer else {
            engine.connect(player, to: node, format: format)
            return
        }
        
        engine.connect(player, to: equalizer, format: format)
        engine.connect(equalizer, to: mixer, format: format)
        engine.connect(mixer, to: node, format: format)
    }
    
    func play() throws {
        guard let engine = engine else {
            GDLogAudioError("The player must be connected to the audio engine before play() can be called!")
            return
        }
        
        guard engine.isRunning else {
            GDLogAudioError("The audio engine must be running before play() can be called!")
            return
        }
        
        try ObjC.catchException { self.player.play() }
    }
    
    func stop() {
        if player.isPlaying {
            player.stop()
        }
    }
    
    func disconnect() {
        engine?.disconnectNodeOutput(player)
        
        if let equalizer = equalizer, let mixer = mixer {
            engine?.disconnectNodeOutput(equalizer)
            engine?.disconnectNodeOutput(mixer)
        }
    }
    
    func detach() {
        engine?.detach(player)
        
        if let equalizer = equalizer, let mixer = mixer {
            engine?.detach(equalizer)
            engine?.detach(mixer)
        }
        
        self.engine = nil
    }
    
    /// Returns a silent buffer in the format of this audio layer. By default, this buffer only has
    /// a single frame of silence, but the buffer can be longer if the `duration` parameter is
    /// provided
    ///
    /// - Parameter duration: Length (in seconds) of the buffer
    /// - Returns: A silent buffer of the appropriate duration with the same format as the rest of the audio layer
    func silentBuffer(duration: TimeInterval = -1.0) -> AVAudioPCMBuffer {
        guard let format = format else {
            let defaultFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: false)!
            return AVAudioPCMBuffer(pcmFormat: defaultFormat, frameCapacity: AVAudioFrameCount(1))!
        }
        
        let frameCount: AVAudioFrameCount = UInt32(max(1, Int(duration * format.sampleRate)))
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            let defaultFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: false)!
            return AVAudioPCMBuffer(pcmFormat: defaultFormat, frameCapacity: AVAudioFrameCount(1))!
        }
        
        if let channels = buffer.floatChannelData {
            for index in 1 ..< Int(format.channelCount) {
                channels[index].assign(repeating: 0.0, count: Int(frameCount))
            }
        } else if let channels = buffer.int16ChannelData {
            for index in 1 ..< Int(format.channelCount) {
                channels[index].assign(repeating: 0, count: Int(frameCount))
            }
        } else if let channels = buffer.int32ChannelData {
            for index in 1 ..< Int(format.channelCount) {
                channels[index].assign(repeating: 0, count: Int(frameCount))
            }
        }
        
        buffer.frameLength = frameCount
        return buffer
    }
}
