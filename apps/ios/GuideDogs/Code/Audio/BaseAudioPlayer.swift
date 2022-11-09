//
//  BaseAudioPlayer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation
import Combine

class BaseAudioPlayer: AudioPlayer {
    
    let id = AudioPlayerIdentifier()
    
    var layers: [PreparableAudioLayer]
    
    let sound: SoundBase
    
    private var _volume: Float = 1.0
    
    var volume: Float {
        get {
            return _volume
        }
        set {
            _volume = newValue
            layers.forEach { $0.volume = _volume }
        }
    }
    
    var state: AudioPlayerState = .notPrepared {
        didSet {
            // If the player is prepared
            guard state == .prepared else {
                if let observer = observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                return
            }
            
            // And the sound is localized
            guard case .localized = sound.type else {
                return
            }
            
            // Then listen for location updates
            observer = NotificationCenter.default.addObserver(forName: Notification.Name.locationUpdated, object: nil, queue: nil) { [weak self] (notification) in
                guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
                    return
                }
                
                self?.update3DProperties(location)
            }
        }
    }
    
    private(set) var isPlaying: Bool = false
    
    private(set) var connectionState: AudioPlayerConnectionState = .notConnected
    
    // MARK: 3D Audio Properties
    
    private var userHeading: Heading?
    
    private(set) var userLocation: CLLocation?
    
    // MARK: Queue
    
    private(set) weak var queue: DispatchQueue!
    
    /// An observer object for listening for location update notifications so that localized 3D
    /// sounds can be properly updated.
    var observer: NSObjectProtocol?
    
    private var cancellable: AnyCancellable?
       
    init?(sound: SoundBase, queue: DispatchQueue) {
        self.layers = (0 ..< sound.layerCount).map { PreparableAudioLayer(eqParameters: sound.equalizerParams(for: $0)) }
        self.sound = sound
        self.queue = queue
        
        if sound is TTSSound {
            cancellable = NotificationCenter.default.publisher(for: .ttsVolumeChanged).sink { [weak self] _ in
                self?.volume = SettingsContext.shared.ttsVolume
            }
        } else {
            cancellable = NotificationCenter.default.publisher(for: .otherVolumeChanged).sink { [weak self] _ in
                self?.volume = SettingsContext.shared.otherVolume
            }
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        
        cancellable?.cancel()
        cancellable = nil
        
        layers.forEach {
            $0.disconnect()
            $0.detach()
        }
    }
    
    func prepare(engine: AVAudioEngine, completion: ((Bool) -> Void)?) {
        fatalError("BaseAudioPlayer must be subclassed, and prepare(:) must be implemented")
    }
    
    func updateConnectionState(_ state: AudioPlayerConnectionState) {
        connectionState = state
    }
    
    func play(_ userHeading: Heading? = nil, _ userLocation: CLLocation? = nil) throws {
        // Make sure `prepare()` was called first (so that we have started rendering audio buffers)
        assert(state == .prepared, "You must call .prepare() before .play()!")
        
        guard state == .prepared else {
            GDLogAudioError("The player must be prepared before it can be played!")
            return
        }
        
        if isPlaying {
            stop()
        }
        
        for index in 0 ..< layers.count {
            scheduleBuffer(forLayer: index)
        }
        
        // If this isn't a 3D sound, then we can ignore the location and heading stuff
        guard is3D else {
            try play()
            return
        }
        
        update3DProperties()
        
        if let loc = userLocation {
            update3DProperties(loc)
        }
        
        self.userHeading = userHeading
        
        userHeading?.onHeadingDidUpdate { [weak self] (heading) in
            guard let value = heading?.value else {
                return
            }
            
            self?.update3DProperties(value)
        }
        
        update3DProperties(userHeading?.value ?? 0.0)

        try play()
    }
    
    func resumeIfNecessary() throws -> Bool {
        guard isPlaying else {
            return false
        }
        
        var resumed = false

        // Resume playback if the player has isPlaying set to true but any of the nodes is stopped
        for layer in layers where !layer.isPlaying {
            try layer.play()
            resumed = true
        }
        
        return resumed
    }
    
    private func play() throws {
        guard state == .prepared else {
            GDLogAudioError("The player must be prepared before it can be played!")
            return
        }
        
        let vol = sound is TTSSound ? SettingsContext.shared.ttsVolume : SettingsContext.shared.otherVolume
        
        for layer in layers {
            layer.volume = vol
            try layer.play()
        }
        
        isPlaying = true
    }
    
    func scheduleBuffer(forLayer: Int) {
        fatalError("BaseAudioPlayer must be subclassed, and scheduleBuffer() must be implemented")
    }
    
    func stop() {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard self.isPlaying else {
                return
            }
                        
            self.state = .notPrepared
            
            for layer in self.layers {
                layer.stop()
                layer.disconnect()
                layer.detach()
            }
            
            if let observer = self.observer {
                NotificationCenter.default.removeObserver(observer)
            }
            
            self.isPlaying = false
            self.userHeading = nil
        }
    }
    
    /// Updates the node's 3D properties. This version of the method is intended for updating 3D properties that
    /// are not dependent on the user's heading or location (e.g. if the sound is using the .compass style).
    private func update3DProperties() {
        switch sound.type {
        case .compass(let compassDirection, _):
            // Both .ring and .real distance rendering styles are rendered the same when using the .compass sound style
            let bearing = compassDirection.add(degrees: 0.0)
            layers.forEach { $0.position = AVAudio3DPoint(from: bearing, distance: DebugSettingsContext.shared.envRenderingDistance)}
                
        default:
            // Changes in the user's location do not affect standard (2D) or relative sounds
            break
        }
    }
    
    /// Updates the node's 3D properties. This version of the method is intended for updating 3D properties that
    /// are dependent on the user's location.
    ///
    /// - Parameter userLocation: The user's current location
    private func update3DProperties(_ userLocation: CLLocation) {
        self.userLocation = userLocation
        
        switch sound.type {
        case .localized(let location, let style) where style == .ring:
            let bearing = userLocation.bearing(to: location)
            layers.forEach { $0.position = AVAudio3DPoint(from: bearing, distance: DebugSettingsContext.shared.envRenderingDistance) }

        case .localized(let location, let style) where style == .real:
            let bearing = userLocation.bearing(to: location)
            layers.forEach { $0.position = AVAudio3DPoint(from: bearing, distance: userLocation.distance(from: location)) }
                
        default:
            // Changes in the user's location do not affect standard (2D) or relative sounds
            break
        }
    }
    
    /// Updates the node's 3D properties. This version of the method is intended for updating 3D properties that
    /// are dependent on the user's heading.
    ///
    /// - Parameter userHeading: User's current heading
    private func update3DProperties(_ userHeading: CLLocationDirection) {
        switch sound.type {
        case .relative(let direction, _):
            // Maintain the relative direction of the sound (both the .real and .ring rendering styles are the same since .relative doesn't reflect distance in callouts)
            let bearing = direction.add(degrees: userHeading)
            layers.forEach { $0.position = AVAudio3DPoint(from: bearing, distance: DebugSettingsContext.shared.envRenderingDistance) }
            
        default:
            // Changes in the user's heading do not affect standard (2D) or localized sounds
            break
        }
    }
    
}
