//
//  AudioParser.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol AudioParser {
    static func getAudioData(data: Data) -> Data?
    static func getSampleRate(data: Data) -> UInt32?
}
