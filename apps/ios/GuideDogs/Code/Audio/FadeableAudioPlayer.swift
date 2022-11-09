//
//  FadeableAudioPlayer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation

class FadeableAudioPlayer: AVAudioPlayer {
    private let queue = DispatchQueue(label: "com.company.appname.fadeableaudioplayer")
    
    private var isFadingIn = false
    private var cancelFadeIn = false
    
    private var isFadingOut = false
    private var cancelFadeOut = false
    
    class func fadeablePlayer(with filename: String, fileTypeHint: String = GAAudioFileDefaultTypeHint, allowSharedFolder: Bool = true) -> FadeableAudioPlayer? {
        // Try to load from shared folder
        if allowSharedFolder, let player = try? FadeableAudioPlayer(sharingFilename: filename, fileTypeHint: fileTypeHint) {
            return player
        }
        
        // Try to load from asset catalog
        if let player = try? FadeableAudioPlayer(assetName: filename, fileTypeHint: fileTypeHint) {
            return player
        }
        
        // Try to load from main bundle
        if let player = try? FadeableAudioPlayer(bundleFilename: filename, fileTypeHint: fileTypeHint) {
            return player
        }
        
        return nil
    }
    
    func fadeIn(to: Float = 1.0, duration: TimeInterval = 1.0) {
        guard !isFadingIn else {
            return
        }
        
        if isFadingOut {
            cancelFadeOut = true
        }
        
        isFadingIn = true
        cancelFadeIn = false
        
        if !isPlaying {
            volume = 0.0
            currentTime = 0.0
            play()
        }
        
        fadeIn(to: to, stepSize: (to * 0.1) / Float(duration))
    }
    
    private func fadeIn(to: Float = 1.0, stepSize: Float) {
        // If stop has been called, then stop trying to fade in
        guard isPlaying, !cancelFadeIn, volume < to else {
            isFadingIn = false
            return
        }
        
        volume += stepSize
        
        queue.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.fadeIn(to: to, stepSize: stepSize)
        }
    }
    
    func fadeOut(to: Float = 0.0, duration: TimeInterval = 1.0, _ completion: (() -> Void)? = nil) {
        guard !isFadingOut else {
            return
        }
        
        if isFadingIn {
            cancelFadeIn = true
        }
        
        isFadingOut = true
        cancelFadeOut = false
        
        fadeOut(to: 0.0, stepSize: ((volume - to) * 0.1) / Float(duration), completion: completion)
    }
    
    private func fadeOut(to: Float = 0.0, stepSize: Float, completion: (() -> Void)? = nil) {
        guard isPlaying, !cancelFadeOut, volume > to else {
            isFadingOut = false
            stop()
            completion?()
            return
        }
        
        volume -= stepSize
        
        queue.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.fadeOut(to: to, stepSize: stepSize, completion: completion)
        }
    }
}
