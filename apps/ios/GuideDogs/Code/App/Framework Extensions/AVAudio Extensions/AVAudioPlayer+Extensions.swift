//
//  AVAudioPlayer+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation.AVFAudio

enum AudioPlayerError: Error {
    case fileNotFound
}

let GAAudioFileDefaultTypeHint = AVFileType.wav.rawValue

extension AVAudioPlayer {
    
    /// Initializes and returns an audio player for playing a resource audio file.
    /// The method tries to find the file in the shared folder, asset catalog and main bundle.
    /// If `allowSharedFolder` is `false`, the shared folder is not checked.
    @objc class func player(with filename: String, allowSharedFolder: Bool) -> AVAudioPlayer? {
        return player(with: filename, fileTypeHint: GAAudioFileDefaultTypeHint, allowSharedFolder: allowSharedFolder)
    }
    
    /// Initializes and returns an audio player for playing a resource audio file.
    /// The method tries to find the file in the shared folder, asset catalog and main bundle.
    /// If `allowSharedFolder` is `false`, the shared folder is not checked.
    class func player(with filename: String, fileTypeHint: String = GAAudioFileDefaultTypeHint, allowSharedFolder: Bool = true) -> AVAudioPlayer? {
        // Try to load from shared folder
        if allowSharedFolder, let player = try? AVAudioPlayer(sharingFilename: filename, fileTypeHint: fileTypeHint) {
            return player
        }
        
        // Try to load from asset catalog
        if let player = try? AVAudioPlayer(assetName: filename, fileTypeHint: fileTypeHint) {
            return player
        }
        
        // Try to load from main bundle
        if let player = try? AVAudioPlayer(bundleFilename: filename, fileTypeHint: fileTypeHint) {
            return player
        }
        
        return nil
    }
    
    /// Initializes and returns an audio player for playing an asset catalog audio file.
    convenience init(assetName: String, fileTypeHint: String = GAAudioFileDefaultTypeHint) throws {
        guard let audioAsset = NSDataAsset(name: assetName) else { throw AudioPlayerError.fileNotFound }
        try self.init(data: audioAsset.data, fileTypeHint: fileTypeHint)
    }
    
    /// Initializes and returns an audio player for playing an audio file from the shared folder.
    convenience init(sharingFilename filename: String, fileTypeHint: String = GAAudioFileDefaultTypeHint) throws {
        guard let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { throw AudioPlayerError.fileNotFound }
        let audioFilePath = (documentsDirectory as NSString).appendingPathComponent("\(filename).\(fileTypeHint)")
        let audioFileUrl = URL(fileURLWithPath: audioFilePath)
        try self.init(contentsOf: audioFileUrl, fileTypeHint: fileTypeHint)
    }
    
    /// Initializes and returns an audio player for playing an audio file from the app main bundle.
    convenience init(bundleFilename filename: String, fileTypeHint: String = GAAudioFileDefaultTypeHint) throws {
        guard let audioFilePath = Bundle.main.path(forResource: filename, ofType: fileTypeHint) else { throw AudioPlayerError.fileNotFound }
        let audioFileUrl = URL(fileURLWithPath: audioFilePath)
        try self.init(contentsOf: audioFileUrl, fileTypeHint: fileTypeHint)
    }
    
}
