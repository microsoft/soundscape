//
//  TTSSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import CoreLocation
import Combine

/// Object that encapsulates the rendering of text to speech using Apple's AVSpeechSynthesizer
/// engine. This sound object asynchronously generates audio buffers for the speech.
class TTSSound: Sound {
    
    // MARK: Sound Protocol Properties
    
    let type: SoundType
    
    let text: String
    
    var layerCount: Int = 1
    
    /// Human-readable description of the sound
    var description: String {
        return "\"\(text)\""
    }
    
    // MARK: Rendered Audio
    
    private typealias Resolver = (AVAudioPCMBuffer?) -> Void
    private var buffers: [AVAudioPCMBuffer] = []
    private var resolvers: [Resolver] = []
    
    // MARK: Rendering State
    
    private var cancellable: AnyCancellable?
    private var completion: Subscribers.Completion<TTSAudioBufferPublisher.Failure>?
    
    // MARK: Queue
    
    private let queue = DispatchQueue(label: "com.company.appname.ttssound")
    
    // MARK: TTS EQ Filters
    
    private struct VoiceEQ: Decodable {
        var id: String
        var filter: EQParameters
    }
    
    static let filters: [String: EQParameters] = {
        guard let path = Bundle.main.path(forResource: "voiceFilters", ofType: "json") else {
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let filterList = try JSONDecoder().decode([VoiceEQ].self, from: data)
            return filterList.reduce(into: [:]) { $0[$1.id] = $1.filter }
        } catch {
            GDLogAppError("Unable to parse voiceFilters.json file!")
            return [:]
        }
    }()
    
    // MARK: Initializers
    
    /// Initialize a standard 2D sound for the text-to-speech
    ///
    /// - Parameter text: Text to render to speech
    init(_ text: String) {
        self.text = text
        self.type = .standard
    }
    
    /// Initialize a localized 3D sound for the text-to-speech
    ///
    /// - Parameters:
    ///   - text: Text to render to speech
    ///   - at: The GPS location the sound is localized with
    init(_ text: String, at: CLLocation) {
        self.text = text
        self.type = .localized(at, .ring)
    }
    
    /// Initialize a relative 3D sound for the text-to-speech
    ///
    /// - Parameters:
    ///   - text: Text to render to speech
    ///   - direction: The relative direction the sound should be localized in (relative to the user)
    init(_ text: String, direction: CLLocationDirection) {
        self.text = text
        self.type = .relative(direction, .ring)
    }
    
    /// Initialize a 3D sound in a compass direction for the text-to-speech
    ///
    /// - Parameters:
    ///   - text: Text to render to speech
    ///   - compass: The compass direction the sound should be localized in (relative to the user)
    init(_ text: String, compass: CLLocationDirection) {
        self.text = text
        type = .compass(compass, .ring)
    }
    
    // MARK: Methods
        
    /// Stops rendering text-to-speech if buffers are still being generated
    func stopRendering() {
        cancellable?.cancel()
    }
    
    /// Takes a buffer and either adds it to the list of prepared buffers or sends it to
    /// a promise that is currently pending waiting for a buffer.
    ///
    /// - Parameter buffer: Buffer to resolve
    private func resolveBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard resolvers.count > 0 else {
            if let buffer = buffer {
                buffers.append(buffer)
            }
            
            return
        }
        
        let resolver = resolvers.removeFirst()
        resolver(buffer)
    }
    
    /// Starts generating audio buffers for the text-to-speech (if they aren't already being generated)
    /// and returns a promise that will be fulfilled as soon as a buffer is ready. When all buffers have
    /// been generated, the returned promise will be fulfilled with a value of `nil`.
    ///
    /// - Parameter index: Layer to generate buffers for. `TTSSounds` only have a single layer, so this should only be 0.
    /// - Returns: A promise that will be fulfilled with the next available buffer
    func nextBuffer(forLayer index: Int) -> Promise<AVAudioPCMBuffer?> {
        guard index == 0 else {
            return Promise<AVAudioPCMBuffer?> { $0(nil) }
        }
        
        // If we haven't already started rendering the audio, do so now
        if cancellable == nil && completion == nil {
            guard let ttsAudioBufferPublisher = TTSAudioBufferPublisher(self.text) else {
                return Promise { $0(nil) }
            }
            
            cancellable = ttsAudioBufferPublisher.receive(on: queue).sink(receiveCompletion: { [weak self] (result) in
                switch result {
                case .failure(let error): GDLogAudioError(error.description)
                default: break
                }
                
                self?.completion = result
                self?.cancellable = nil
                self?.resolveBuffer(nil)
            }, receiveValue: { [weak self] (buffer) in
                self?.resolveBuffer(buffer)
            })
        }
        
        let nextBuffer: AVAudioPCMBuffer? = queue.sync {
            if buffers.count > 0 {
                return buffers.removeFirst()
            }
            
            return nil
        }
        
        // If we have a buffer, we can resolve immediately
        if let buff = nextBuffer {
            return Promise { $0(buff) }
        }
        
        // If we don't have any buffers and we are done generating, then resolve immediately with nil
        guard completion == nil else {
            return Promise { $0(nil) }
        }
        
        // Otherwise, create a new promise that will resolve as soon as the next buffer is rendered
        return Promise { resolve in
            self.queue.sync {
                self.resolvers.append(resolve)
            }
        }
    }
}

extension TTSSound: SoundBase {
    /// Looks up the optional equalizer parameters for a given layer
    func equalizerParams(for layerIndex: Int) -> EQParameters? {
        guard layerIndex == 0 else {
            return nil
        }
        
        let gain = SettingsContext.shared.ttsGain
        
        if let id = SettingsContext.shared.voiceId {
            let parameters = TTSSound.filters[id]?.bandParameters
            
            guard parameters != nil || gain != 0 else {
                return nil
            }
            
            return EQParameters(globalGain: gain, parameters: parameters ?? [])
        }
        
        guard let defaultVoiceId = TTSConfigHelper.defaultVoice(forLocale: LocalizationContext.currentAppLocale)?.identifier else {
            return nil
        }
        
        let parameters = TTSSound.filters[defaultVoiceId]?.bandParameters
        
        guard parameters != nil || gain != 0 else {
            return nil
        }
        
        return EQParameters(globalGain: gain, parameters: parameters ?? [])
    }
}
