//
//  AudioFileStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Combine

class AudioFileStore: ObservableObject {
    @Published var isDownloaded: Bool = false
    @Published var duration: TimeInterval = 0.0
    @Published var elapsed: TimeInterval = 0.0
    @Published var isPlaying: Bool = false
    
    private(set) var activityID: String?
    private(set) var remoteURL: URL?
    
    private(set) var localURL: URL?
    private(set) var playerID: AudioPlayerIdentifier?
    private var timer: Timer?
    private var downloadListener: AnyCancellable?
    private var finishedListener: AnyCancellable?
    private var stoppedListener: AnyCancellable?
    
    /// Initializer that should only be used during design-time. This initializer overrides the default
    /// behavior in order to fake the isDownloaded state value to match the provided value.
    ///
    /// - Parameter overrideIsDownloaded: Override value to apply during design time
    convenience init(overrideIsDownloaded: Bool = false) {
        self.init()
        
        isDownloaded = overrideIsDownloaded
    }
    
    deinit {
        downloadListener?.cancel()
        downloadListener = nil
        
        finishedListener?.cancel()
        finishedListener = nil
        
        stoppedListener?.cancel()
        stoppedListener = nil
    }
    
    func load(activityID: String, remoteURL: URL) {
        self.activityID = activityID
        self.remoteURL = remoteURL
        
        defer {
            if let url = localURL {
                let sound = GenericSound(url)
                duration = sound.duration ?? 0.0
            }
        }
        
        guard !AuthoredActivityLoader.shared.audioClipExists(activityID: activityID, remoteURL: remoteURL) else {
            localURL = AuthoredActivityLoader.shared.localAudioFileURL(activityID: activityID, remoteURL: remoteURL)
            isDownloaded = true
            return
        }
        
        downloadListener = NotificationCenter.default.publisher(for: .activityAudioClipDownloaded).receive(on: RunLoop.main).sink { notification in
            guard let id = notification.userInfo?[AuthoredActivityLoader.Keys.activityId] as? String, id == activityID else {
                return
            }
            
            guard let remote = notification.userInfo?[AuthoredActivityLoader.Keys.activityId] as? String, remote == remoteURL.path else {
                return
            }
            
            guard let local = notification.userInfo?[AuthoredActivityLoader.Keys.activityId] as? String else {
                return
            }
            
            self.localURL = URL(fileURLWithPath: local)
            self.isDownloaded = true
        }
    }
    
    func start() {
        GDATelemetry.track("waypoint.audio.start")
        
        guard let url = localURL else {
            return
        }
        
        finishedListener = NotificationCenter.default.publisher(for: .discretePlayerFinished).receive(on: RunLoop.main).sink { notification in
            guard let id = notification.userInfo?[AudioEngine.Keys.playerId] as? AudioPlayerIdentifier else {
                return
            }
            
            guard self.playerID == id else {
                return
            }
            
            GDATelemetry.track("waypoint.audio.complete")
            
            self.cleanupFinishedPlayer()
        }
        
        stoppedListener = NotificationCenter.default.publisher(for: .discretePlayerDidStop).receive(on: RunLoop.main).sink { notification in
            guard let id = notification.userInfo?[AudioEngine.Keys.playerId] as? AudioPlayerIdentifier else {
                return
            }
            
            guard self.playerID == id else {
                return
            }
            
            GDATelemetry.track("waypoint.audio.stopped")
            
            self.cleanupFinishedPlayer()
        }
        
        playerID = AppContext.shared.audioEngine.play(GenericSound(url))
        
        let tickTock = Timer(timeInterval: 0.05, repeats: true, block: { _ in self.elapsed += 0.05 })
        RunLoop.main.add(tickTock, forMode: .default)
        timer = tickTock
        
        isPlaying = true
    }
    
    func stop() {
        GDATelemetry.track("waypoint.audio.stop")
        
        guard let id = playerID else {
            return
        }
        
        AppContext.shared.audioEngine.stop(id)
        cleanupFinishedPlayer()
    }
    
    private func cleanupFinishedPlayer() {
        isPlaying = false
        
        finishedListener?.cancel()
        finishedListener = nil
        
        stoppedListener?.cancel()
        stoppedListener = nil
        
        timer?.invalidate()
        timer = nil
        elapsed = 0.0
        
        playerID = nil
    }
}
