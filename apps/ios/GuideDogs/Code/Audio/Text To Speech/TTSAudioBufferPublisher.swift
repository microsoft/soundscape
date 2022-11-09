//
//  TTSAudioBufferPublisher.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import Combine

enum TTSError: Error, CustomStringConvertible {
    case cancelled
    case failedToRender
    case unableToConvert
    
    var description: String {
        switch self {
        case .cancelled: return "Synthesizer cancelled before finishing"
        case .failedToRender: return "Synthesizer failed to render any output. Voice may be broken"
        case .unableToConvert: return "Unable to convert synthesizer output to PCMFloat32"
        }
    }
}

struct TTSAudioBufferPublisher: Publisher {
    typealias Output = AVAudioPCMBuffer
    typealias Failure = TTSError
    
    let text: String
    let voiceId: String?
    
    init?(_ text: String, voiceIdentifier: String? = nil) {
        guard let voiceId = voiceIdentifier ??
                SettingsContext.shared.voiceId ??
                TTSConfigHelper.defaultVoice(forLocale: LocalizationContext.currentAppLocale)?.identifier else {
            return nil
        }
        
        self.voiceId = voiceId
        self.text = text
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = TTSSubscription(subscriber: subscriber, text: text, voiceIdentifier: voiceId)
        subscriber.receive(subscription: subscription)
    }
}

private extension TTSAudioBufferPublisher {
    final class TTSSubscription<S: Subscriber>: NSObject, AVSpeechSynthesizerDelegate, Subscription where Output == S.Input, Failure == S.Failure {
        private var subscriber: S? {
            didSet {
                if subscriber == nil {
                    synth?.delegate = nil
                    synth = nil
                }
            }
        }
        
        private var synth: AVSpeechSynthesizer?
        private let utterance: AVSpeechUtterance
        private var buffers: [AVAudioPCMBuffer] = []
        private var lock: NSRecursiveLock = .init()
        
        private var requested: Subscribers.Demand = .none
        private var processed: Subscribers.Demand = .none
        
        private var completion: Subscribers.Completion<S.Failure>?
        
        private let voiceId: String?
        private var voice: AVSpeechSynthesisVoice? {
            guard let id = voiceId else {
                return nil
            }
            
            return AVSpeechSynthesisVoice(identifier: id)
        }
        
        init(subscriber: S, text: String, voiceIdentifier: String? = nil) {
            self.voiceId = voiceIdentifier
            
            // Format the text for tts
            var formatted = LanguageFormatter.expandCodedDirection(for: text)
            formatted = PostalAbbreviations.format(formatted, locale: LocalizationContext.currentAppLocale)
            formatted = formatted.replacingOccurrences(of: "_", with: " ")
            
            // Initialize parameters
            self.subscriber = subscriber
            self.utterance = AVSpeechUtterance(string: formatted)
            super.init()
            
            // Configure the utterance
            utterance.rate = SettingsContext.shared.speakingRate
            utterance.voice = voice
            
            synth = AVSpeechSynthesizer()
            synth?.delegate = self
            synth?.write(utterance) { [weak self] buffer in
                self?.receiveBuffer(buffer)
            }
        }
        
        // MARK: Subscription
        
        func request(_ demand: Subscribers.Demand) {
            flush(demand)
        }
        
        // MARK: Cancellable
        
        func cancel() {
            synth?.stopSpeaking(at: .immediate)
            buffers.removeAll()
            subscriber = nil
        }
        
        // MARK: AVSpeechSynthesizer
        
        private func receiveBuffer(_ buffer: AVAudioBuffer) {
            lock.lock()
            
            defer {
                lock.unlock()
                flush()
            }
            
            // The buffer should be a PCM buffer and there should be some data in it
            guard let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 else {
                return
            }
            
            // Get ready to convert the buffer to PCMFloat32 from PCMInt16:
            //   1. Keep the audio in the same layout except move to the PCMFloat32 common format
            //   2. Create an audio converter from PCMInt16 to PCMFloat32
            //   3. Create a new buffer with the appropriate format
            guard let floatFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: pcm.format.sampleRate, channels: pcm.format.channelCount, interleaved: pcm.format.isInterleaved),
                let converter = AVAudioConverter(from: pcm.format, to: floatFormat),
                let convertedBuffer = AVAudioPCMBuffer(pcmFormat: floatFormat, frameCapacity: pcm.frameLength) else {
                completion = .failure(.unableToConvert)
                return
            }

            convertedBuffer.frameLength = pcm.frameLength

            // Convert the Apple TTS from PCMInt16 to PCMFloat32
            do {
                try converter.convert(to: convertedBuffer, from: pcm)
            } catch {
                GDLogAudioError("Unable to convert TTS data: \(error.localizedDescription)")
                completion = .failure(.unableToConvert)
                return
            }

            // Save the converted buffer
            buffers.append(convertedBuffer)
        }
        
        private func flush(_ adding: Subscribers.Demand = .none) {
            lock.lock()
            
            defer {
                lock.unlock()
            }
            
            guard let subscriber = subscriber else {
                buffers.removeAll()
                return
            }
            
            // Add the new demand request to the current request
            requested += adding
            
            // Send as many audio buffers as we can
            while !buffers.isEmpty, processed < requested {
                requested += subscriber.receive(buffers.remove(at: 0))
                processed += 1
            }
            
            // If we have finished (we are out of buffers and the synth is done), then send the completion
            if buffers.isEmpty, let completion = completion {
                subscriber.receive(completion: completion)
                self.subscriber = nil
            }
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            completion = processed > 0 ? .finished : .failure(.failedToRender)
            flush()
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            completion = processed > 0 ? .failure(.cancelled) : .failure(.failedToRender)
            flush()
        }
        
    }
}
