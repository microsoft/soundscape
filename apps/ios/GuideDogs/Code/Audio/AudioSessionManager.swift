//
//  AudioSessionManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol AudioSessionManagerDelegate: AnyObject {
    func sessionDidActivate()
    func interruptionBegan()
    func interruptionEnded(shouldResume: Bool)
    func mediaServicesWereReset()
    func onOutputRouteOverriden(_ override: AVAudioSession.PortOverride)
}

/// A class that manages the app's audio session (`AVAudioSession`) for audio output.
class AudioSessionManager {

    weak var delegate: AudioSessionManagerDelegate?
    
    // MARK: Properties
    
    let session = AVAudioSession.sharedInstance()
    
    var needsActivation: Bool = true
    
    private var isInSpeakerMode: Bool = false
    
    /// This will contain a value if there was an error activating the audio session
    @objc var activationError: NSError?
    
    /// Returns `true` if the current audio session can support remote control events
    private var canInvokeRemoteControlEvents: Bool {
        return !isMixingWithOthers
    }
    
    /// Returns `true` if the current audio session should mix with others
    var mixWithOthers: Bool {
        didSet {
            if oldValue != mixWithOthers {
                configureAudioSession()
            }
        }
    }
    
    /// Returns `true` if the current audio session supports mixing with others
    private var isMixingWithOthers: Bool {
        return session.categoryOptions.contains(.mixWithOthers)
    }
    
    /// A Boolean value that indicates whether another application is playing audio.
    private var isOtherAudioPlaying: Bool {
        // Apple recommends using this instead of `isOtherAudioPlaying`
        return session.secondaryAudioShouldBeSilencedHint
    }
    
    /// Returns the current port type description
    var outputType: String {
        guard let output = session.currentRoute.outputs.first else { return "unknown" }
        return output.portType.rawValue
    }
    
    /// Returns a dictionary of current state information, useful for telemetry.
    var currentStateInfo: [String: String] {
        return ["output_type": outputType,
                "is_other_audio_playing": String(isOtherAudioPlaying),
                "is_mixing_with_others": String(isMixingWithOthers)]
    }
    
    // MARK: Initialization
    
    init(mixWithOthers: Bool) {
        self.mixWithOthers = mixWithOthers
        
        registerObservers()
        configureAudioSession()
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: Observers

    private func registerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaServicesWereReset(_:)),
                                               name: AVAudioSession.mediaServicesWereResetNotification,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionRouteChange(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionSilenceSecondaryAudioHint(_:)),
                                               name: AVAudioSession.silenceSecondaryAudioHintNotification,
                                               object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.mediaServicesWereResetNotification,
                                                  object: session)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
                                                  object: session)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.routeChangeNotification,
                                                  object: session)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.silenceSecondaryAudioHintNotification,
                                                  object: session)
    }
    
    // MARK: Methods

    /// - Returns: `true` if audio session configuration was successful, `false` otherwise.
    @discardableResult
    private func configureAudioSession() -> Bool {
        do {
            try session.setCategory(.playback,
                                    mode: .default,
                                    options: mixWithOthers ? [.mixWithOthers] : [])
            GDLogAudioSessionInfo("Category set (playback, default, options: \(mixWithOthers ? "mixWithOthers" : "none"))")
        } catch let error as NSError {
            let avError = AVAudioSession.ErrorCode(rawValue: error.code) ?? .unspecified
            
            GDLogAudioSessionWarn("An error occured setting the audio session category: \(error) \(avError.description)")
            
            var telemetryInfo = currentStateInfo
            telemetryInfo["error.code"] = String(error.code)
            telemetryInfo["error.description"] = error.description
            telemetryInfo["av_error.description"] = avError.description
            GDATelemetry.track("audio_session.set_category.error", with: telemetryInfo)
            
            return false
        }
        
        return true
    }
    
    private func shouldActivate() -> Bool {
        // If we are not mixing with others and there is another app playing audio, only allow activating when we are in the foreground.
        // - note: the audio engine trys to activate the audio session when it trys to output audio.
        // If we allow for this to happen anytime, other apps that play audio (Music, Podcasts) will be deactivated even if they are in the foreground.
        if !mixWithOthers && isOtherAudioPlaying {
            return AppContext.isActive
        }
        
        return needsActivation
    }
    
    /// Activate the audio session.
    /// - Parameter force: Force activation, discarding the `shouldActivate()` check.
    /// - Returns: `true` if audio session activation was successful, `false` otherwise.
    @discardableResult
    func activate(force: Bool = false) -> Bool {
        guard force || shouldActivate() else {
            GDLogAudioSessionWarn("Audio session does not currently need activation. Skipping...")
            return false
        }
        
        do {
            try session.setActive(true, options: [])
        } catch let error as NSError {
            let avError = AVAudioSession.ErrorCode(rawValue: error.code) ?? .unspecified
            
            GDLogAudioSessionWarn("An error occured activating the audio session: \(error) \(avError.description)")
            
            var telemetryInfo = currentStateInfo
            telemetryInfo["error.code"] = String(error.code)
            telemetryInfo["error.description"] = error.description
            telemetryInfo["av_error.description"] = avError.description
            GDATelemetry.track("audio_session.set_active.error", with: telemetryInfo)
            
            activationError = error
            needsActivation = true
            return false
        }
        
        needsActivation = false
        activationError = nil
        
        GDLogAudioSessionInfo("Audio session activated")
        
        if !mixWithOthers {
            // Note: The app is capable of using the remote controls only when the `.mixWithOthers` category option is `false`.
            // Only apps which don't mix with others (such as Music, Podcasts) are allowed by iOS to control the media controls.
            // This means apps that mix with others (like navigation) which play short audio clips cannot use the controls.
            // This is because they are supposed to "mix with others", and if music is playing and a navigational app
            // is playing, the iOS will not know which one to control.
            becomeNowPlayingApp()
        }
        
        delegate?.sessionDidActivate()
        
        return true
    }
    
    /// Deactivate the audio session.
    /// - Returns: `true` if audio session deactivation was successful, `false` otherwise.
    @discardableResult
    func deactivate() -> Bool {
        do {
            try session.setActive(false, options: [])
        } catch let error as NSError {
            let avError = AVAudioSession.ErrorCode(rawValue: error.code) ?? .unspecified

            GDLogAudioSessionWarn("An error occured deactivating the audio session: \(error) \(avError.description)")

            var telemetryInfo = currentStateInfo
            telemetryInfo["error.code"] = String(error.code)
            telemetryInfo["error.description"] = error.description
            telemetryInfo["av_error.description"] = avError.description
            GDATelemetry.track("audio_session.set_inactive.error", with: telemetryInfo)

            return false
        }
        
        GDLogAudioSessionInfo("Audio session deactivated")
        
        needsActivation = true
        
        return true
    }
    
    private func becomeNowPlayingApp() {
        guard MPNowPlayingInfoCenter.default().nowPlayingInfo == nil else {
            return
        }
        
        AudioSessionManager.setNowPlayingInfo(title: "")
    }
    
    // MARK: Notification Callbacks
    
    @objc func handleMediaServicesWereReset(_ notification: NSNotification) {
        configureAudioSession()
        delegate?.mediaServicesWereReset()
    }
    
    @objc func handleAudioSessionInterruption(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            GDLogAudioSessionInfo("Interruption occurred. Error parsing user info.")
            return
        }
        
        switch type {
        case .began:
            // The interruption is due to the audio session being deactivated when the system suspended the app. Activation is required when appropriate.
            let wasSuspended = (userInfo[AVAudioSessionInterruptionWasSuspendedKey] as? Bool) ?? false
            
            GDLogAudioSessionInfo("Interruption occurred (type: began, options: none\(wasSuspended ? ", reason: wasSuspended" : "")\(AppContext.shared.callManager.callInProgress ? ", call in progress" : ""))")
            
            // Because of continuous live audio apps, we cannot know when the other audio player has stopped
            // when coming back from background we need to know when to activate
            if !mixWithOthers || wasSuspended {
                needsActivation = true
            }
            
            delegate?.interruptionBegan()
        case .ended:
            /// The `shouldResume` option can be used as a hint for the type of the ended audio interruption. For example:
            /// If a continuous audio player has been paused, such as pausing the Music app, we should expect `shouldResume` == `false`.
            /// If a non-continuous audio player has been paused, such as stopping a video on Facebook, we should expect `shouldResume` == `true`.
            let shouldResume: Bool
            
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            } else {
                shouldResume = false
            }
            
            GDLogAudioSessionInfo("Interruption occurred (type: ended, options: \(shouldResume ? "shouldResume" : "none"))")

            if shouldResume || !mixWithOthers {
                needsActivation = true
            }
            
            self.delegate?.interruptionEnded(shouldResume: shouldResume)
        default:
            break
        }
    }
    
    @objc func handleAudioSessionRouteChange(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            GDLogAudioSessionInfo("Route change occurred. Could not parse user info.")
            return
        }
        
        // Log and track information
        let reasonValue = (userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt) ?? AVAudioSession.RouteChangeReason.unknown.rawValue
        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        let reasonDescription = reason?.description ?? "unknown"
        
        let previousOutput = (userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription)?.outputs.first
        let previousOutputType = previousOutput?.portType.rawValue ?? "unknown"
        let previousOutputName = previousOutput?.portName ?? "unknown"
        
        let currentOutput = session.currentRoute.outputs.first
        let currentOutputType = currentOutput?.portType.rawValue ?? "unknown"
        let currentOutputName = currentOutput?.portName ?? "unknown"
        
        GDLogAudioSessionInfo("Route change occurred (reason: \(reasonDescription))")

        GDLogAudioSessionInfo("Previous route output: \(previousOutputType) (\(previousOutputName))")
        GDLogAudioSessionInfo("Current route output: \(currentOutputType) (\(currentOutputName))")
        
        // Handle speaker mode logic if needed
        if let reason = reason, reason == .override, let output = currentOutput, output.portType == .builtInSpeaker {
            delegate?.onOutputRouteOverriden(.speaker)
            isInSpeakerMode = true
        } else if isInSpeakerMode, let output = currentOutput, output.portType != .builtInSpeaker {
            delegate?.onOutputRouteOverriden(.none)
            isInSpeakerMode = false
        }
        
        GDATelemetry.track("audio_session.route_change", with: ["previous": previousOutputType,
                                                                "current": currentOutputType,
                                                                "reason": reasonDescription.replacingOccurrences(of: " ", with: "_")])
    }
    
    @objc func handleAudioSessionSilenceSecondaryAudioHint(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
            let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else {
            GDLogAudioSessionInfo("Silence secondary audio hint notification. Could not parse user info.")
                return
        }
        
        GDLogAudioSessionInfo("Silence secondary audio hint notification. type: \(type) (\(type == .begin ? "other app audio started playing - mute secondary audio" : "other app audio stopped playing - restart secondary audio"))")
    }
    
    func enableSpeakerMode() -> Bool {
        guard !isInSpeakerMode else {
            return false
        }
        
        do {
            // `overrideOutputAudioPort` requires the `playAndRecord` category
            try session.setCategory(.playAndRecord, mode: .default, options: session.categoryOptions)
            try session.overrideOutputAudioPort(.speaker)
        } catch {
            GDLogAppError("Unable to temporarily override output audio port. error: \(error)")
            return false
        }
        
        GDLogAudioSessionInfo("Audio session output port set to speaker mode")
        return true
    }
    
    func disableSpeakerMode() -> Bool {
        guard isInSpeakerMode else {
            return false
        }
        
        do {
            try session.setCategory(.playback, mode: .default, options: session.categoryOptions)
            try session.overrideOutputAudioPort(.none)
        } catch {
            GDLogAppError("Unable to reset the overriden output audio port. error: \(error)")
            return false
        }
        
        GDLogAudioSessionInfo("Audio session output port set to default mode")
        return true
    }
}

extension AudioSessionManager {
    
    /// iOS 'Now Playing' display format:
    /// For iOS < 16:
    /// +---------------------------------+
    /// | "Title"                         |
    /// | "Subtitle — Secondary Subtitle" |
    /// +---------------------------------+
    /// For iOS > 16:
    /// The "Secondary Subtitle" is only shown when expending the
    /// now playing in the Control Center with a long press.
    /// +---------------------------------+
    /// | "Title"                         |
    /// | "Subtitle"                      |
    /// +---------------------------------+
    class func setNowPlayingInfo(title: String, subtitle: String? = nil, secondarySubtitle: String? = nil) {
        var info: [String: Any] = [
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPMediaItemPropertyTitle: title
        ]
        
        if let subtitle = subtitle, let secondarySubtitle = secondarySubtitle {
            info[MPMediaItemPropertyArtist] = "\(subtitle) — \(secondarySubtitle)" // Uses a "em dash"
        } else if let subtitle = subtitle {
            info[MPMediaItemPropertyArtist] = subtitle
        } else if let secondarySubtitle = secondarySubtitle {
            info[MPMediaItemPropertyArtist] = secondarySubtitle
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    class func removeNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
}
