//
//  GlyphSound.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

/// This class is a very simple wrapper of `GenericSound`. It simply overrides the
/// `description` property of `GenericSound` in order to have Glyphs be logged differently
/// from other sounds.
class GlyphSound: GenericSound {
    
    /// Human-readable description of the sound
    override var description: String {
        switch source {
        case .file(let url):
            return "[\(url.lastPathComponent)]"
        case .bundle(let asset):
            return "[\(asset.name)]"
        }
    }
    
}
