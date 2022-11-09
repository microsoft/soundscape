//
//  AudioEngine.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation

extension Notification.Name {
    static let audioEngineStateChanged = Notification.Name("GDAAudioEngineStateChanged")
    static let dynamicPlayerFinished = Notification.Name("GDADynamicPlayerFinished")
    static let discretePlayerFinished = Notification.Name("GDADiscretePlayerFinished")
    static let discretePlayerDidStop = Notification.Name("GDADiscretePlayerDidStop")
}

/// This class builds and runs a graph of audio player nodes for playing all types of audio in
/// Soundscape. This includes 3D and 2D audio. All 3D audio is localized using the HRTF algorithm
/// built into Apple's `AVAudioEnvironmentNode`.
///
/// The node graph built by this object is completely dynamic. 2D audio players have their nodes
/// connected directly to the audio engine's main mixer node (which outputs to the speakers/headphones).
/// 3D audio players' nodes are connected to an environment node that is configured to work with audio at
/// the same sample rate as the 3D audio player. This means that there may be multiple environment nodes
/// (since there could be multiple 3D audio streams playing at different sample rates at the same time).
/// All environment nodes are then connected to the audio engine's main mixer node.
///
///     {3D Players @ 48 kHz} ------|--- [Environment Node] ---|
///                                                            |
///     {3D Players @ 22.05 kHz} ---|--- [Environment Node] ---|
///                                                            |
///     {etc...} -------------------|--- [Environment Node] ---|--- [Main Mixer] ---> (Output to Speakers)
///                                                            |
///                                            {2D Players} ---|
///
///
/// The audio engine can play both discrete audio (non-looped audio; see `DiscreteAudioPlayer` and
/// `AudioEngineAsset`) and continuous audio (looped audio; see `ContinuousAudioPlayer` and
/// `DynamicAudioEngineAsset`). When assets are passed into the audio engine using one of the various
/// `play(...)` methods, the appropriate type of audio player is created, attached to the engine, and
/// started. Discrete audio players are removed from the engine when they are done playing. Continuous
/// audio players are removed from the engine when `stop(_:)` is called with the id for the continuous
/// audio player. The audio engine has no knowledge of the implementation details of the various types
/// of audio in Soundscape as those details are fully encapsulated in the objects that implement
/// `AudioEngineAsset`, `Sound` (for discrete sounds), and/or `DynamicAudioEngineAsset` (for continuous
/// sounds) . See examples of this in `ClassicBeacon.swift`, `V2Beacon.swift`, `ContinuousTrack`, `WandAsset.swift`,
/// `GlyphSound.swift`, `TTSSound.swift`, and `GenericSound.swift`.
class AudioEngine: AudioEngineProtocol {
    
    // MARK: Types
    
    enum State: Int {
        case stopped
        case starting
        case started
    }
    
    // MARK: Keys
    
    struct Keys {
        static let audioEngineStateKey = "GDAAudioEngineStateKey"
        static let playerId = "GDAAudioPlayerID"
    }
    
    // MARK: Audio Session
    
    private var sessionManager: AudioSessionManager
    
    var session: AVAudioSession {
        return sessionManager.session
    }
    
    var outputType: String {
        return sessionManager.outputType
    }
    
    private var isConfigChangePending = false
    
    private var isSessionInterrupted = false
    
    private var isAwaitingRouteOverride = false
    
    private var routeOverrideCompletionHandler: ((AVAudioSession.PortOverride) -> Void)?
    
    private var state = State.stopped {
        didSet {
            guard state != oldValue else {
                return
            }
            
            // Store the current value, as it might change while switching threads
            let state = self.state
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioEngineStateChanged,
                                                object: self,
                                                userInfo: [AudioEngine.Keys.audioEngineStateKey: state.rawValue])
            }
        }
    }
    
    // MARK: Engine
    
    weak var delegate: AudioEngineDelegate?
    private var engine: AVAudioEngine
    
    // MARK: Nodes and Players
    
    private var environmentNodes: [AVAudioEnvironmentNode] = []
    private var players: [AudioPlayer] = []
    private var discretePlayerIds: [AudioPlayerIdentifier] = []
    
    // MARK: Sound Queue
    
    private var soundsQueue = Queue<(Sounds, CompletionCallback?)>()
    private var currentSounds: Sounds?
    private var currentSoundCompletion: CompletionCallback?
    private var currentQueuePlayerID: AudioPlayerIdentifier?
    
    // MARK: Environment Info
    
    private weak var envSettings: EnvironmentSettingsProvider!
    private var userLocation: CLLocation?
    private var userHeading: Heading?
    
    // MARK: Recording State
    
    private(set) var isRecording = false
    private var recordingFile: AVAudioFile?
    
    static var recordingDirectory: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("AudioRecordings")
    }
    
    // MARK: Notification Observers
    
    private var engineConfigObserver: NSObjectProtocol?
    private var applicationStateObserver: NSObjectProtocol?
    private var callStateObserver: NSObjectProtocol?
    
    // MARK: Dispatch Queue
    
    private let queue = DispatchQueue(label: "com.company.appname.audioengine")
    
    // MARK: Public State
    
    /// This property is `true` when the output format of the engine only has one channel (e.g.
    /// the audio route is the iPhone speakers instead of stereo headphones), or when the mono audio
    /// accessibility setting is enabled. While it is not currently implemented, this could also be exposed
    /// as a user setting within Soundscape as well.
    private(set) var isInMonoMode: Bool = false
    
    /// Computed property that is `true` when there is currently discrete audio playing
    var isDiscreteAudioPlaying: Bool {
        return discretePlayerIds.contains { id in players.first(where: { $0.id == id })?.isPlaying ?? false }
    }
    
    var mixWithOthers: Bool {
        get {
            return sessionManager.mixWithOthers
        }
        set {
            guard sessionManager.mixWithOthers != newValue else {
                return
            }
            
            sessionManager.deactivate()
            pause()
            stop()
            sessionManager.mixWithOthers = newValue
            start()
        }
    }
    
    // MARK: - Initialization
    
    init(envSettings: EnvironmentSettingsProvider, mixWithOthers: Bool) {
        self.envSettings = envSettings
        
        // Create the engine (all nodes are dynamically generated, so none are created in this initializer)
        engine = AVAudioEngine()
        
        sessionManager = AudioSessionManager(mixWithOthers: mixWithOthers)
        
        // Listen for events from the audio session
        sessionManager.delegate = self
        
        // Listen for changes to the engine configuration so we can re-establish connections if connection
        // formats need to change (specifically for the environment node).
        engineConfigObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak self] (_) in
            GDLogAudioVerbose("Engine configuration changed. Reconnecting nodes and restarting engine.")
            
            self?.resetConfiguration()
        }
        
        // In some cases, it is necessary to restart the audio engine after the application did become active. See `start()` for more details.
        applicationStateObserver = NotificationCenter.default.addObserver(forName: .appDidBecomeActive, object: nil, queue: nil) { [weak self] (_) in
            GDLogAudioVerbose("Application did become active. Restarting engine.")
            
            guard let `self` = self else {
                return
            }
            
            self.queue.sync {
                self.start()
            }
        }
        
        callStateObserver = NotificationCenter.default.addObserver(forName: .callStatusChanged, object: nil, queue: nil) { [weak self] (notification) in
            guard let `self` = self else { return }
            
            guard let userInfo = notification.userInfo,
                let typeValue = userInfo[CallManager.Keys.callStatusTypeKey] as? UInt,
                let type = CallStatusType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                // Handled by the audio session interruption
                break
            case .ended:
                // Handled here as some interruption ended notifications may not be delivered by iOS
                guard self.isSessionInterrupted else {
                    return
                }
                
                GDLogAudioVerbose("Call ended. Restarting engine.")
                
                self.queue.sync {
                    self.start()
                }
            }
        }
        
        GDLogAudioVerbose("Initializing audio engine")
        
        // Call `connectNodes()` so that `isInMonoMode` gets set up (even though there aren't any nodes to connect yet)
        connectNodes()
    }
    
    deinit {
        if let observer = engineConfigObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = applicationStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = callStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: Engine Configuration
    
    private func resetConfiguration() {
        GDLogAudioVerbose("Resetting configuration")
        
        // Track the state of connections of player nodes to the audio graph
        for player in players {
            player.updateConnectionState(.unknown)
        }
        
        if engine.outputNode.outputFormat(forBus: 0).sampleRate == 0 || engine.outputNode.outputFormat(forBus: 0).channelCount == 0 {
            GDLogAudioError("Output is not currenly enabled...")
        }
        
        queue.sync {
            guard !isSessionInterrupted else {
                // Will reset configuration after audio session interruption ends
                isConfigChangePending = true
                
                GDLogAudioVerbose("Configuration change is pending audio interruption")
                return
            }
            
            guard state != .stopped else {
                // Will reset configuration when audio engine starts
                isConfigChangePending = true
                
                GDLogAudioVerbose("Configuration change is pending audio engine start")
                return
            }
            
            isConfigChangePending = false
            connectNodes()
            start()
        }
    }
    
    /// Updates the value of `isInMonoMode` by checking the audio engine's current output configuration
    /// and then reconnects all current nodes in the audio engine (regardless of whether `isInMonoMode`
    /// changed or not). This is required when an engine configuration change is detected (e.g. when the
    /// audio route changes) since the configuration change may require audio format changes to occur in
    /// the node connections in the audio engine's node graph.
    private func connectNodes() {
        // Update mono mode property
        isInMonoMode = engine.outputNode.outputFormat(forBus: 0).channelCount == 1 || UIAccessibility.isMonoAudioEnabled
        GDLogAudioVerbose("Connecting audio graph in \(isInMonoMode ? "2D" : "3D") mode (from \(Thread.current.threadName))")
        
        // Access the `mainMixerNode` property so that the node gets constructed by the audio engine before we
        // try to connect any other nodes. If this isn't referenced here, it will cause a crash
        // when we try to detach the first player that plays...
        engine.mainMixerNode.volume = 1.0
        engine.mainMixerNode.outputVolume = 1.0
        
        // Clean up environment nodes that are still attached to the engine from it's previous configuration
        for environment in environmentNodes {
            guard let envEngine = environment.engine else {
                continue
            }
            
            envEngine.disconnectNodeInput(environment)
            envEngine.disconnectNodeOutput(environment)
            envEngine.detach(environment)
        }
        
        // Connect the environment nodes to the main mixer
        do {
            try ObjC.catchException {
                // Connect the audio players
                for player in self.players {
                    self.connectNodes(for: player)
                }
            }
        } catch {
            GDLogAudioError(error.localizedDescription)
            GDATelemetry.track("audio_engine.exception", with: [
                "description": error.localizedDescription,
                "location": "AudioEngine.swift:connectNodes()"
            ])
        }
    }
    
    /// Connects the `AVAudioPlayerNode` of an `AudioPlayer` to the audio engine. If the `AudioPlayer`
    /// only plays standard 2D audio, or if the audio engine is currently in mono mode, then the
    /// player node will be connected directly to the engine's main mixer node. If the `AudioPlayer`
    /// plays 3D audio, this method will find or create the appropriate `AVAudioEnvironment` node,
    /// connect it to the engine if it isn't already, and connect the player's node to it instead of
    /// connecting the player node directly to the engine's main mixer node.
    ///
    /// - Parameter player: The player to connect to the audio engine
    private func connectNodes(for player: AudioPlayer) {
        // Only prepared players can be connected to the audio graph (guarantees the node is attached to the engine)
        guard player.state == .prepared else {
            return
        }
        
        engine.mainMixerNode.outputVolume = 1.0
        
        for layer in player.layers {
            // Wire the node up with the audio engine
            connectLayer(layer, for: player)
        }
        
        player.updateConnectionState(.connected)
    }
    
    private func connectLayer(_ layer: PreparableAudioLayer, for player: AudioPlayer) {
        guard layer.isAttached else {
            GDLogAudioError("Tried to connect layer within engine, but layer has not yet been attached. This condition should not be possible")
            return
        }
        
        // Disconnect any existing connections
        do {
            try ObjC.catchException { layer.disconnect() }
        } catch {
            GDLogAudioError(error.localizedDescription)
            GDATelemetry.track("audio_engine.exception", with: [
                "description": error.localizedDescription,
                "location": "AudioEngine.swift:connectNodes(for:)"
            ])
        }
        
        if isInMonoMode || !player.is3D {
            layer.connect(to: engine.mainMixerNode)
        } else {
            // Lookup or create the environment node
            let knownEnv = environmentNode(for: layer.format)
            let environment = knownEnv ?? AVAudioEnvironmentNode()
            
            // If it's new, save it
            if knownEnv == nil {
                // Save the environment node for future use
                environmentNodes.append(environment)
                GDLogAudioVerbose("[ENV] Environment node created for sample rate \(layer.format?.sampleRate ?? -1) Hz (\(environmentNodes.count) total nodes)")
                
                if let userHeading = userHeading?.value {
                    // Initialize orientation for new environment nodes
                    environment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: Float(userHeading), pitch: 0.0, roll: 0.0)
                }
            }
            
            // If it's not attached, attach and connect it
            if environment.engine == nil {
                engine.attach(environment)
                GDLogAudioVerbose("[ENV] Attached environment node to engine (sample rate: \(layer.format?.sampleRate ?? -1) Hz)")
            }
            
            // Configure 3D rendering/mixing parameters
            environment.reverbParameters.enable = envSettings.envRenderingReverbEnable
            environment.reverbParameters.level = envSettings.envRenderingReverbLevel
            environment.reverbParameters.loadFactoryReverbPreset(envSettings.envRenderingReverbPreset)
            
            if envSettings.envReverbFilterActive {
                environment.reverbParameters.filterParameters.bandwidth = envSettings.envReverbFilterBandwidth
                environment.reverbParameters.filterParameters.bypass = envSettings.envReverbFilterBypass
                environment.reverbParameters.filterParameters.filterType = envSettings.envReverbFilterType
                environment.reverbParameters.filterParameters.frequency = envSettings.envReverbFilterFrequency
                environment.reverbParameters.filterParameters.gain = envSettings.envReverbFilterGain
            }
            
            environment.distanceAttenuationParameters.referenceDistance = 2.0
            environment.outputVolume = 1.0
            
            // Connect the player to the environment
            layer.connect(to: environment)
            engine.connect(environment, to: engine.mainMixerNode, format: AudioEngine.outputFormat(for: engine, sampleRate: layer.format?.sampleRate))
            GDLogAudioVerbose("[ENV] Connected layer to environment node then to engine (sample rate: \(layer.format?.sampleRate ?? -1) Hz)")
        }
    }
    
    /// Returns the environment node that matches the sample rate of the provided format if one
    /// already exists. If a matching node does not yet exist, this method will create one and
    /// return it.
    ///
    /// - Parameter format: Format of the audio that is going to be played using the environment node
    ///
    /// - Returns: An environment node that can play audio of with the specified format
    private func environmentNode(for format: AVAudioFormat?) -> AVAudioEnvironmentNode? {
        guard let format = format else {
            return environmentNodes.first
        }
        
        // If we already have an environment node for this sample rate, return it
        if let node = environmentNodes.first(where: { $0.inputFormat(forBus: 0).sampleRate == format.sampleRate }) {
            return node
        }
        
        return nil
    }
    
    /// Builds an `AVAudioFormat` object using the current channel count of the engine's output node
    /// and either the sample rate provided or the sample rate of the output node of the engine if a
    /// sample rate isn't provided. This is useful for setting the format of processing nodes (e.g. environment
    /// nodes). Nodes that load their audio from a buffer or file, should use the format of the buffer or
    /// file instead of this method.
    ///
    /// - Parameter rate: The rate to use in the format
    ///
    /// - Returns: An `AVAudioFormat` object
    private class func outputFormat(for engine: AVAudioEngine, sampleRate rate: Double? = nil) -> AVAudioFormat {
        let channels = engine.outputNode.outputFormat(forBus: 0).channelCount
        let sampleRate = rate ?? engine.outputNode.outputFormat(forBus: 0).sampleRate

        var layout: AVAudioChannelLayout?
        
        // This is probably overkill since we will likely never connect to any output other than stereo or mono...
        
        switch channels {
        case 4: layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_4)
        case 5: layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_5_0)
        case 6: layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_6_0)
        case 7: layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_7_0)
        case 8: layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_8)
        default: layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Stereo)
        }
        
        guard let selectedLayout = layout else {
            // This shouldn't ever happen, but still have a sensible fallback
            GDLogAudioError("Channel layout is nil")
            return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: false)!
        }

        return AVAudioFormat(standardFormatWithSampleRate: sampleRate, channelLayout: selectedLayout)
    }
    
    // MARK: Start & Stop
    
    /// Before starting the audio engine, we check for phone call status and app state.
    /// In some cases the flow of notifications is:
    /// 1. Call started
    /// 2. Application state inactive
    /// 3. Audio session interruption began
    ///
    /// In other cases (detected on iPhone X):
    /// 1. Call started
    /// 2. Audio session interruption began
    /// 3. Application state inactive
    ///
    /// When a phone call ends, the flow of notifications is:
    /// 1. Call ended
    /// 2. Audio session interruption ended
    /// 3. Application state active
    private func shouldStart() -> Bool {
        if state == .starting {
            GDLogAudioVerbose("Audio engine does not need to be started (it is already being started)")
            return false
        }
        
        // No need to start the engine if it's already running
        if engine.isRunning {
            GDLogAudioVerbose("Audio engine does not need to be started (it is already running)")
            return false
        }
        
        // Don't allow starting the engine if the app is inactive
        if AppContext.appState == .inactive {
            GDLogAudioVerbose("Audio engine does not need to be started (app state is inactive)")
            return false
        }
        
        // Don't allow starting the engine if there is a call in progress and the app is not in an active state
        if AppContext.shared.callManager.callInProgress && AppContext.appState != .active {
            GDLogAudioVerbose("Audio engine does not need to be started (a call is in progress and Soundscape isn't active)")
            return false
        }
        
        return true
    }
    
    /// In some cases we stop the audio engine, such as an audio session interruption,
    /// but because of iOS behavior where some 'audio session interruption ended' notifications
    /// are not received, we don't know that the audio engine should be restarted.
    /// For example: invoking and dismissing Siri while in foreground.
    /// This makes sure we restart the audio engine if needed.
    private func startEngineIfNeeded() {
        guard AppContext.appState == .active && shouldStart() else {
            return
        }
        
        start()
    }
    
    /// Starts the audio engine and starts listening for heading updates in order to update the
    /// listener's orientation in any `AVAudioEnvironment` nodes.
    ///
    /// - Parameter isRestarting: True if this method is being called from within the playNextSound chain
    /// - Parameter activateAudioSession: True if this method should also activate the audio session
    func start(isRestarting: Bool, activateAudioSession: Bool = true) {
        // Don't try to start when the app is inactive, such as when Siri is invoked,
        // as it will generate the error "cannot interrupt other".
        guard AppContext.appState != .inactive else {
            return
        }
        
        if activateAudioSession {
            // We try to forcibly activate the audio session, even if we believe it's not needed (`needsActivation == false`).
            // This is because of the following issue:
            // iOS does not provide a callback when the audio session was deactivated, or, a boolean to note if the session is active or not.
            // Also, iOS may deactivate the audio session in the background, such as when activating Siri or finishing a call in the background.
            // In this case, we need to try and reactivate the session to use the audio engine.
            guard sessionManager.activate(force: true) else {
                GDLogAudioError("Unable to start audio engine. Failed to activate the audio session.")
                return
            }
            
            // If the audio session was interrupted, but we successfully reactivated it, make sure to revert to `false`.
            isSessionInterrupted = false
        }
        
        guard shouldStart() else {
            // If the audio engine has started, make sure all the paused players are resumed if needed.
            if state == .started {
                if !resume() {
                    // If resuming wasn't successful because one of the players could not be resumed,
                    // that player will be marked as done. If this was the case, try to play the
                    // next sound, which will either play or report finished.
                    playNextSound()
                }
            }
            return
        }
        
        if isConfigChangePending {
            connectNodes()
            isConfigChangePending = false
        }
        
        state = .starting
        
        GDLogAudioInfo("Starting audio engine (from \(Thread.current.threadName))\(isRestarting ? " (restarting)" : "")")
        
        do {
            try engine.start()
        } catch let error as NSError {
            state = .stopped
            
            // The engine couldn't be started
            let avError = AVAudioSession.ErrorCode(rawValue: error.code) ?? .unspecified
            
            GDLogAudioError("Audio engine could not be started (\(error)) \(avError.description)")
            
            GDATelemetry.track("audio_engine.exception", with: [
                "error.code": String(error.code),
                "error.description": error.description,
                "av_error.description": avError.description,
                "location": "AudioEngine.swift:start()"
            ])
            
            return
        }
        
        state = .started
        
        // Listen to the user's heading in order to update the listener's orientation
        userHeading = AppContext.shared.geolocationManager.presentationHeading
        
        if let heading = userHeading?.value {
            self.updateUserHeading(heading)
        }
        
        userHeading?.onHeadingDidUpdate { [weak self] (heading) in
            guard let `self` = self, let heading = heading else {
                return
            }
            
            self.updateUserHeading(heading.value)
        }
        
        // Check if there are any discrete audio players to resume. If there are none (or none that need resumed),
        // then try to play the next sound in case there are other sounds in the queue.
        if !isRestarting && !resume() {
            playNextSound()
        }
    }
    
    /// Temporary method for handling changes to the audio session category and should only be called when changing the `mixWithOthers` property.
    /// In cases of external interruptions like audio engine configuration changes or audio session interruptions, iOS stops nodes.
    /// When manually changing the audio session category we need to do this ourselves to resume the audio engine and players properly.
    private func pause() {
        for player in players {
            for layer in player.layers {
                layer.player.stop()
            }
        }
    }
    
    /// Stops the audio engine and stops listening to user orientation updates
    func stop() {
        userHeading = nil
        engine.stop()
        state = .stopped
        
        /// In order to minimize re-activision issues, we should try to not deactivate the audio session and let iOS do that when needed.
        /// Because of this, use `needsActivation = true` instead of `deactivate()`...
        sessionManager.needsActivation = true

        GDLogAudioVerbose("Audio engine stopped (from \(Thread.current.threadName))")
    }
    
    @discardableResult
    private func resume() -> Bool {
        GDLogAudioVerbose("Resuming \(players.count) players")
        
        // Resume players as need be
        var didResume = false
        
        for player in players {
            let isDiscrete = player is DiscreteAudioPlayer
            GDLogAudioVerbose("Trying to resume player \(player.id.uuidString) (discrete? \(isDiscrete))")
            
            let didResumePlayer: Bool
            do {
                didResumePlayer = (try player.resumeIfNecessary()) || startPlayerIfPending(player)
            } catch {
                GDLogAudioError("Unable to resume player. Exception: \((error as NSError).localizedFailureReason ?? error.localizedDescription)")
                GDATelemetry.track("audio_engine.exception", with: [
                    "description": error.localizedDescription,
                    "location": "AudioEngine.swift:resume()"
                ])
                
                continue
            }
            
            GDLogAudioVerbose("\(didResumePlayer ? "Resumed" : "Unable to resume") player \(player.id.uuidString)")
            
            if isDiscrete {
                if didResumePlayer {
                    didResume = true
                } else {
                    // If a discrete player could not be resumed, remove it from queue by marking it as done.
                    // Without this, the player could be stuck in a `playing` state without actually playing.
                    onDataPlayedBack(player.id)
                }
            }
        }
        
        return didResume
    }
    
    private func startPlayerIfPending(_ player: AudioPlayer) -> Bool {
        guard player.state == .prepared, !player.isPlaying else {
            return false
        }
        
        GDLogAudioVerbose("Starting pending player \(player.id.uuidString)")
        startPreparedPlayer(player)
        return true
    }
    
    // MARK: Audio Players
    
    /// Starts an audio player by calling the `prepare` method and then playing the audio as soon
    /// as the player finishes preparing itself. This method stores the audio player in the engine's
    /// list of current players and returns the player's identifier so that the player can be looked
    /// up later (for stopping it).
    ///
    /// - Parameters:
    ///   - player: The player to start
    ///   - heading: The heading object to pass to the player when it is started
    ///
    /// - Returns: A unique identifier for the player. `nil` if the player couldn't be started.
    private func play(_ player: AudioPlayer, heading: Heading? = nil) -> AudioPlayerIdentifier? {
        players.append(player)
        player.prepare(engine: engine) { [weak self] (success) in
            guard success else {
                GDLogAudioError("Unable to play audio track. Preparing the player failed.")
                
                // Automatically remove the player here since it couldn't be prepared
                self?.players.removeAll(where: { $0.id == player.id })
                
                if player is DiscreteAudioPlayer {
                    self?.discretePlayerIds.removeAll { $0 == player.id }
                    
                    if player.id == self?.currentQueuePlayerID {
                        self?.currentQueuePlayerID = nil
                        self?.playNextSound()
                    }
                }
                
                return
            }

            self?.startPreparedPlayer(player, heading: heading)
        }
        
        return player.id
    }
    
    /// This method starts playing an audio player that is ready to be played. This method should
    /// only be called on players that done being prepared.
    ///
    /// - Parameters:
    ///   - player: The audio player to start
    ///   - heading: The heading required by the audio player to render it's audio. This is only required by some audio players.
    private func startPreparedPlayer(_ player: AudioPlayer, heading: Heading? = nil) {
        queue.async { [unowned self] in
            guard !player.isPlaying else {
                GDLogAudioError("No need to start an audio player that is already playing.")
                return
            }
            
            guard player.state == .prepared else {
                GDLogAudioError("Cannot start an audio player that is not ready. Make sure to call prepare()!")
                return
            }
            
            guard !self.isConfigChangePending else {
                GDLogAudioError("Unable to play audio track. Config change is pending")
                return
            }
            
            if !self.engine.isRunning {
                self.start(isRestarting: true)
            }
            
            guard self.engine.isRunning else {
                GDLogAudioError("Unable to play audio track. Audio engine is not currently running.")
                return
            }
            
            self.connectNodes(for: player)
            self.logPlayer(player)
            
            do {
                try player.play(heading ?? AppContext.shared.geolocationManager.presentationHeading, self.userLocation)
            } catch {
                let exceptionString = (error as NSError).localizedFailureReason ?? error.localizedDescription
                GDLogAudioError("Exception: \(exceptionString)")
                GDATelemetry.track("audio_engine.exception", with: [
                    "description": error.localizedDescription,
                    "location": "AudioEngine.swift:startPreparedPlayer(_:heading:).1"
                ])
                
                // Restart the engine
                self.stop()
                self.start(isRestarting: true)
                
                // Connect nodes and retry one time
                self.connectNodes()
                self.logPlayer(player)
                
                do {
                    try player.play(heading ?? AppContext.shared.geolocationManager.presentationHeading, self.userLocation)
                } catch {
                    GDLogAudioError("Exception (final try): \((error as NSError).localizedFailureReason ?? error.localizedDescription)")
                    GDATelemetry.track("audio_engine.exception", with: [
                        "description": error.localizedDescription,
                        "location": "AudioEngine.swift:startPreparedPlayer(_:heading:).2"
                    ])
                }
            }
        }
    }
    
    private func logPlayer(_ player: AudioPlayer) {
        let playerType = player is DiscreteAudioPlayer ? "Discrete" : "Continuous"
        let monoMode = self.isInMonoMode ? " <MONO MODE>" : ""
        GDLogAudioInfo("Play \(playerType): \(player.sound.formattedLog)\(monoMode) at \(Int(player.volume * 100))% (\(player.id))")
    }
    
    /// Asynchronously stops a dynamic audio player by calling it's finish() func. If the
    /// dynamic audio player's sound has an outro asset, then finish() will schedule the
    /// outro to play before it calls stop().
    ///
    /// - Parameter dynamicPlayerId: ID of a dynamic audio player
    func finish(dynamicPlayerId: AudioPlayerIdentifier) {
        guard let player = players.first(where: { $0.id == dynamicPlayerId }) as? FinishableAudioPlayer else {
            return
        }
        
        player.finish()
    }
    
    /// Stops the audio player associated with the provided identifier. This operation is completed
    /// asynchronously on the audio engine's queue in order to support thread safety and prevent
    /// race conditions.
    ///
    /// - Parameter playerId: The identifier of the audio player to stop
    func stop(_ playerId: AudioPlayerIdentifier) {
        queue.async { [unowned self] in
            guard let index = self.players.firstIndex(where: { $0.id == playerId }) else {
                return
            }
            
            let player = self.players.remove(at: index)
            player.stop()
            
            if let discrete = player as? DiscreteAudioPlayer, let ttsSound = discrete.sound as? TTSSound {
                ttsSound.stopRendering()
            }
            
            GDLogAudioVerbose("Stopping player \(player.id.uuidString)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .discretePlayerDidStop, object: self, userInfo: [ Keys.playerId: playerId ])
            }
        }
    }
    
    // MARK: - Continuous Audio
    
    /// Plays a sound based on a dynamic audio asset using the provided heading object to select
    /// the appropriate component of the dynamic asset component to play at any given time.
    ///
    /// - Parameters:
    ///   - sound: The dynamic sound to play
    ///   - heading: Heading used for selecting the dynamic asset component to play. If `nil`, the default presentation heading will be used.
    ///
    /// - Returns: A unique identifier for the player. `nil` if the player couldn't be started.
    @discardableResult
    func play<T: DynamicSound>(_ sound: T, heading: Heading? = nil) -> AudioPlayerIdentifier? {
        return queue.sync {
            self.startEngineIfNeeded()
            
            guard self.state != .stopped else {
                GDLogAudioError("Unable to play sounds. Audio engine is stopped.")
                return nil
            }
            
            guard let player = DynamicAudioPlayer(sound: sound, queue: queue) else {
                GDLogAudioError("Unable to play dynamic audio asset. Unable to load audio assets.")
                return nil
            }
            
            player.delegate = self
            
            // Dynamic assets require a heading for selecting the component to play, so default to the presentation
            // heading if no heading was provided
            return play(player, heading: heading ?? AppContext.shared.geolocationManager.presentationHeading)
        }
    }
    
    /// Plays audio in a continuous loop.
    ///
    /// - Parameter sound: A synchronously generated sound to play
    ///
    /// - Returns: A unique identifier for the player. `nil` if the player couldn't be started.
    @discardableResult
    func play(looped: SynchronouslyGeneratedSound) -> AudioPlayerIdentifier? {
        return queue.sync {
            self.startEngineIfNeeded()
            
            guard self.state != .stopped else {
                GDLogAudioError("Unable to play sounds. Audio engine is stopped.")
                return nil
            }
            
            guard let player = ContinuousAudioPlayer(looped, queue: queue) else {
                GDLogAudioError("Unable to play continuous audio track. Unable to load audio assets.")
                return nil
            }
            
            return play(player)
        }
    }
    
    @discardableResult
    /// Plays a sound without queuing it. This method is intended for playing simple audio files
    ///
    /// - Parameter sound: Sound to play
    /// - Returns: Player ID
    func play(_ sound: SynchronouslyGeneratedSound) -> AudioPlayerIdentifier? {
        return queue.sync {
            self.startEngineIfNeeded()
            
            guard self.state != .stopped else {
                GDLogAudioError("Unable to play sounds. Audio engine is stopped.")
                return nil
            }
            
            guard let player = DiscreteAudioPlayer(sound, queue: self.queue) else {
                GDLogAudioError("Unable to play audio track. Unable to load audio assets.")
                return nil
            }
            
            player.delegate = self
            
            if let id = self.play(player) {
                self.discretePlayerIds.append(id)
                return id
            }
            
            return nil
        }
    }
    
    // MARK: Discrete Queued Audio
    
    /// Plays a discrete `Sound` and calls the `completion` callback when the sound has finished
    /// playing.
    ///
    /// - Parameter sounds: Sound to play
    /// - Parameter callback: Completion callback
    func play(_ sound: Sound, completion callback: CompletionCallback? = nil) {
        play(Sounds(sound), completion: callback)
    }
    
    /// Plays the discrete sounds contained in the `Sounds` object and calls the `completion` callback when
    /// the sounds have finished playing.
    ///
    /// - Parameter sounds: Sounds to play
    /// - Parameter callback: Completion callback
    func play(_ sounds: Sounds, completion callback: CompletionCallback? = nil) {
        queue.async { [unowned self] in
            self.startEngineIfNeeded()
            
            guard self.state != .stopped else {
                GDLogAudioError("Unable to play sounds. Audio engine is stopped.")
                callback?(false)
                return
            }
            
            if !self.engine.isRunning {
                self.start()
            }
        
            guard self.engine.isRunning else {
                self.soundsQueue.enqueue((sounds, callback))
                GDLogAudioError("Unable to play sounds. Audio engine is not currently running. Sounds enqueued. Total queued items: \(self.soundsQueue.count)")
                return
            }
            
            // In some cases we have a value in `currentSounds`, but it's sounds array is empty.
            // In this case discard the current sounds object.
            if let currentSounds = self.currentSounds, currentSounds.isEmpty {
                self.currentSounds = nil
            }
            
            guard self.currentSounds == nil else {
                self.soundsQueue.enqueue((sounds, callback))
                GDLogAudioError("Unable to play sounds. There are current sounds playing. Sounds enqueued. Total queued items: \(self.soundsQueue.count)")
                return
            }
            
            self.currentSounds = sounds
            self.currentSoundCompletion = callback
            self.playNextSound()
        }
    }
    
    /// Stops any discrete sounds that are currently playing
    ///
    /// - Parameter with: Sound that should be played when the current sounds are stopped. This
    ///                   should be used for earcons that indicate audio is stopping.
    func stopDiscrete(with: Sound?) {
        queue.async { [unowned self] in
            if !self.soundsQueue.isEmpty {
                GDLogAudioInfo("Clearing sounds queue (\(self.soundsQueue.count) items)")
                self.soundsQueue.clear()
            }
            
            guard self.currentSounds != nil else {
                return
            }
            
            GDLogAudioInfo("Stopping discrete sounds")
            
            if let stoppingSound = with {
                self.soundsQueue.enqueue((Sounds(stoppingSound), nil))
            }
            
            // Stop all of the discrete player nodes
            self.discretePlayerIds.forEach { self.stop($0) }
            self.discretePlayerIds.removeAll()
            self.currentQueuePlayerID = nil
            
            self.finishDiscrete(success: false)
        }
    }
    
    private func stopAndRemoveDiscretePlayer(_ id: AudioPlayerIdentifier) {
        guard discretePlayerIds.contains(id) else {
            return
        }
        
        discretePlayerIds.removeAll { $0 == id }
        
        if id == currentQueuePlayerID {
            currentQueuePlayerID = nil
        }
        
        guard let index = self.players.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let player = self.players.remove(at: index)
        
        for layer in player.layers {
            layer.stop()
            layer.detach()
        }
    }
    
    /// Starts playing the next sound if there are more sounds to be played in the current
    /// `Sound` object. If there are no sounds left to play, then `finishDiscrete(:)` is
    /// called so that the next `Sounds` object in the queue can be played.
    private func playNextSound() {
        guard !isAwaitingRouteOverride else {
            return
        }
        
        queue.async { [unowned self] in
            guard self.currentQueuePlayerID == nil else {
                GDLogAudioError("Tried to play next sound when the current sound was still playing (\(String(describing: self.currentQueuePlayerID)))...")
                return
            }
            
            // Get the next sound
            guard let sound = self.currentSounds?.next() else {
                self.delegate?.didFinishPlaying()
                self.finishDiscrete(success: true)
                return
            }
            
            // Create a new discrete audio player and start it
            guard let player = DiscreteAudioPlayer(sound, queue: self.queue) else {
                return
            }
            
            player.delegate = self
            
            if let id = self.play(player) {
                self.discretePlayerIds.append(id)
                self.currentQueuePlayerID = id
            }
        }
    }
    
    /// Called when the current `Sounds` object is done playing. Checks if there
    /// are any more `Sounds` objects in the queue and starts the next one if there are.
    ///
    /// - Parameter success: Indicates if the sounds finished playing successfully
    private func finishDiscrete(success: Bool) {
        let callback = self.currentSoundCompletion
        
        self.currentSounds = nil
        self.currentSoundCompletion = nil
        
        // If other sounds are waiting, start them before
        if let (nextSounds, completion) = self.soundsQueue.dequeue() {
            self.play(nextSounds, completion: completion)
        }
        
        callback?(success)
    }
    
    // MARK: 3D Audio Environment
    
    /// Method for updating the `listenerAngularOrientation` of all `AVAudioEnvironment` nodes
    /// in the audio engine whenever there are presentation heading updates.
    ///
    /// - Parameter heading: Updated presentation heading
    private func updateUserHeading(_ heading: CLLocationDirection) {
        queue.async { [unowned self] in
            for environment in self.environmentNodes {
                environment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: Float(heading), pitch: 0.0, roll: 0.0)
            }
        }
    }
    
    /// Method for updating the user's location in the audio engine. This is used by some audio
    /// players when calculating where audio should be played.
    ///
    /// - Parameter location: User's updated location
    func updateUserLocation(_ location: CLLocation) {
        userLocation = location
    }
    
    // MARK: Recording Output
    
    func startRecording() {
        self.startEngineIfNeeded()
        
        guard self.state != .stopped else {
            GDLogAudioError("Unable to start recording. Audio engine is stopped.")
            return
        }
        
        let engineFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let settings: [String: Any] = [AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                                       AVSampleRateKey: NSNumber(value: engineFormat.sampleRate),
                                       AVNumberOfChannelsKey: NSNumber(value: engineFormat.channelCount),
                                       AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.high.rawValue)]
        
        guard let format = AVAudioFormat(settings: settings) else {
            return
        }
        
        do {
            guard let directory = AudioEngine.recordingDirectory else {
                return
            }
            
            // Check for directories and create them if necessary
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime
            
            let url = directory.appendingPathComponent(formatter.string(from: Date())).appendingPathExtension("m4a")
            recordingFile = try AVAudioFile(forWriting: url, settings: format.settings, commonFormat: .pcmFormatFloat32, interleaved: engineFormat.isInterleaved)
        } catch {
            GDLogAudioError("Unable to create file to record to (\(error))")
        }
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] (buffer, _) in
            do {
                try self?.recordingFile?.write(from: buffer)
            } catch {
                GDLogAudioError("Unable to record buffer...")
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        engine.mainMixerNode.removeTap(onBus: 0)
        recordingFile = nil
        isRecording = false
    }
    
    // MARK: Speakerphone Mode
    
    func enableSpeakerMode(_ handler: ((AVAudioSession.PortOverride) -> Void)? = nil) {
        routeOverrideCompletionHandler = handler
        isAwaitingRouteOverride = sessionManager.enableSpeakerMode()
        
        if !isAwaitingRouteOverride {
            GDLogAudioError("Enabling speaker mode failed")
        }
    }
    
    func disableSpeakerMode(_ handler: ((AVAudioSession.PortOverride) -> Void)? = nil) {
        routeOverrideCompletionHandler = handler
        isAwaitingRouteOverride = sessionManager.disableSpeakerMode()
        
        if !isAwaitingRouteOverride {
            GDLogAudioError("Disabling speaker mode failed")
        }
    }
}

// MARK: - DiscreteAudioPlayerDelegate

extension AudioEngine: DiscreteAudioPlayerDelegate {
    /// Delegate method that is called when a `Sound` object finishes playing all of its audio
    func onDataPlayedBack(_ playerId: AudioPlayerIdentifier) {
        guard discretePlayerIds.contains(playerId) else {
            return
        }
        
        GDLogAudioVerbose("Player done (\(playerId.uuidString))")
        
        let shouldPlayNextSound = currentQueuePlayerID == playerId
        
        // Stop the player and remove it's id from tracking (we must check the currentQueuePlayerID against the playerId before doing this)
        stopAndRemoveDiscretePlayer(playerId)
        
        if shouldPlayNextSound {
            playNextSound()
        } else {
            NotificationCenter.default.post(name: Notification.Name.discretePlayerFinished, object: nil, userInfo: [Keys.playerId: playerId])
        }
    }
    
    func onLayerFormatChanged(_ playerId: AudioPlayerIdentifier, layer: Int) {
        guard let player = players.first(where: { $0.id == playerId }) else {
            return
        }
        
        connectLayer(player.layers[layer], for: player)
        self.logPlayer(player)
    }
}

// MARK: - FinishableAudioPlayerDelegate

extension AudioEngine: FinishableAudioPlayerDelegate {
    func onPlayerFinished(_ playerId: AudioPlayerIdentifier) {
        stop(playerId)
        
        NotificationCenter.default.post(name: Notification.Name.dynamicPlayerFinished, object: nil, userInfo: [Keys.playerId: playerId])
    }
}

// MARK: - AudioSessionManagerDelegate

extension AudioEngine: AudioSessionManagerDelegate {
    
    func sessionDidActivate() {
        // Not all `interruptionBegan()` will be followed by `interruptionEnded()`.
        // Make sure the interruption flag is cleared if the audio session is re-activated.
        isSessionInterrupted = false
        
        start(activateAudioSession: false)
    }
    
    /// When the audio session mixes with others, interruptions will only be
    /// received for actual interruptions, such as Siri and phone calls.
    func interruptionBegan() {
        guard !mixWithOthers else {
            // If we mix with others, we don't want to stop the audio engine.
            return
        }
        
        isSessionInterrupted = true
        
        self.queue.async {
            // Stop discrete players
            self.stopDiscrete()
            
            // Stop audio engine
            self.stop()
        }
    }
    
    /// Apple: "Apps that don't require user input to begin audio playback (such as games)
    /// can ignore the `shouldResume` flag and resume playback when an interruption ends."
    func interruptionEnded(shouldResume: Bool) {
        isSessionInterrupted = false
        
        guard shouldResume || mixWithOthers else {
            return
        }
        
        // Note: currently, there is no way of pausing and resuming audio players that were stopped by iOS.
        // For discrete audio it does not matter, as we discard them if they were interrupted, but for
        // continuous audio players we need to manually re-create them if needed.
        
        self.queue.async {
            self.start()
        }
    }
    
    func mediaServicesWereReset() {
        GDLogAudioVerbose("Media services were reset. Reconnecting nodes and restarting engine.")
        
        engine = AVAudioEngine()
        
        if let observer = engineConfigObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Listen for changes to the engine configuration so we can re-establish connections if connection
        // formats need to change (specifically for the environment node).
        engineConfigObserver = NotificationCenter.default.addObserver(forName: Notification.Name.AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak self] (_) in
            GDLogAudioVerbose("Engine configuration changed. Reconnecting nodes and restarting engine.")
            
            self?.resetConfiguration()
        }
        
        // Update all the players with the new engines
        for player in players {
            for layer in player.layers {
                layer.detach()
                layer.attach(to: engine)
            }
        }
        
        connectNodes()
        start()
    }
    
    func onOutputRouteOverriden(_ override: AVAudioSession.PortOverride) {
        guard isAwaitingRouteOverride else {
            return
        }
        
        isAwaitingRouteOverride = false
        routeOverrideCompletionHandler?(override)
        routeOverrideCompletionHandler = nil
    }
    
}
