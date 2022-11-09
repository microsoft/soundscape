//
//  TTSVoiceValidator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation
import Combine

class TTSVoiceValidator {
    let identifier: String
    
    private var cancellable: AnyCancellable?
    
    init(identifier voice: String) {
        self.identifier = voice
    }
    
    func validate() -> Future<Bool, Never> {
        return Future { [weak self] promise in
            guard let id = self?.identifier,
                  let voice = AVSpeechSynthesisVoice(identifier: id),
                  let ttsAudioBufferPublisher = TTSAudioBufferPublisher(voice.name, voiceIdentifier: id) else {
                promise(.success(false))
                return
            }
            
            self?.cancellable = ttsAudioBufferPublisher.collect().sink(receiveCompletion: { [weak self] (result) in
                switch result {
                case .failure: promise(.success(false))
                case .finished: promise(.success(true))
                }
                
                self?.cancellable = nil
            }, receiveValue: { (_) in
                // Intentional no-op
            })
        }
    }
}
