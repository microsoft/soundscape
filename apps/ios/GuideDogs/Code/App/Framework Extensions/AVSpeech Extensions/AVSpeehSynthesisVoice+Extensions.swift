//
//  AVSpeehSynthesisVoice+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

extension AVSpeechSynthesisVoice {
    /// Checks if there is an enhanced version of this voice available. If this voice is
    /// already is an enhanced voice, this method will return false.
    ///
    /// - Returns: True if there is an enhanced voice available, False otherwise.
    func hasEnhancedVersion() -> Bool {
        guard identifier.contains("com.apple.ttsbundle"), identifier.contains("compact"), !identifier.contains("siri") else {
            return false
        }
        
        return true
    }
    
    /// Checks if this voice should have an enhanced version and if that enhanced version is already downloaded
    ///
    /// - Returns: True if this is a compact voice and there is an available voice with the premium version of this voice's identifier
    func hasEnhancedVersionDownloaded() -> Bool {
        guard hasEnhancedVersion() else {
            return false
        }
        
        return AVSpeechSynthesisVoice.speechVoices().contains { $0.identifier == self.identifier.replacingOccurrences(of: "compact", with: "premium")}
    }
}
