//
//  VoiceTableViewCellDelegate.swift
//  Openscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

protocol VoiceTableViewCellDelegate: AnyObject {
    func didSelectPreview(voice: AVSpeechSynthesisVoice)
}
