//
//  RemoteCommandManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import MediaPlayer

enum RemoteCommand: String {
    case play, pause, stop, togglePlayPause, nextTrack, previousTrack, seekForward, seekBackward
}

protocol RemoteCommandManagerDelegate: AnyObject {
    func remoteCommandManager(_ remoteCommandManager: RemoteCommandManager, handle event: RemoteCommand) -> Bool
}

protocol RemoteCommandManagerDeviceDelegate: AnyObject {
    func onRemotePlayCommand() -> Bool
    func onRemotePauseCommand() -> Bool
}

/// A class that handles the remote control actions of an audio playing app.
class RemoteCommandManager: NSObject {
    
    // MARK: Properties
    
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    // We keep track of seek events to make sure `beginSeeking` and `endSeeking` are delivered properly
    private var currentSeekForwardEvent: MPSeekCommandEvent?
    private var currentSeekBackwardEvent: MPSeekCommandEvent?

    private var didBeginSeekingForwardEvent: Bool {
        guard let currentSeekEvent = currentSeekForwardEvent else { return false }
        return currentSeekEvent.type == .beginSeeking
    }
    
    private var didBeginSeekingBackwardEvent: Bool {
        guard let currentSeekEvent = currentSeekBackwardEvent else { return false }
        return currentSeekEvent.type == .beginSeeking
    }
    
    weak var delegate: RemoteCommandManagerDelegate?
    weak var deviceDelegate: RemoteCommandManagerDeviceDelegate?
    
    // MARK: MPRemoteCommand Activation/Deactivation Methods

    func toggleCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(handleTogglePlayPauseCommandEvent(_:)))
          
            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(handleNextTrackCommandEvent(_:)))
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(handlePreviousTrackCommandEvent(_:)))
            
            remoteCommandCenter.seekForwardCommand.addTarget(self, action: #selector(handleSeekForwardCommandEvent(_:)))
            remoteCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(handleSeekBackwardCommandEvent(_:)))
        } else {
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(handleTogglePlayPauseCommandEvent(_:)))
           
            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(handleNextTrackCommandEvent(_:)))
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(handlePreviousTrackCommandEvent(_:)))
            
            remoteCommandCenter.seekForwardCommand.removeTarget(self, action: #selector(handleSeekForwardCommandEvent(_:)))
            remoteCommandCenter.seekBackwardCommand.removeTarget(self, action: #selector(handleSeekBackwardCommandEvent(_:)))
        }
        
        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
        
        remoteCommandCenter.nextTrackCommand.isEnabled = enable
        remoteCommandCenter.previousTrackCommand.isEnabled = enable
        
        remoteCommandCenter.seekForwardCommand.isEnabled = enable
        remoteCommandCenter.seekBackwardCommand.isEnabled = enable
    }
    
    // MARK: MPRemoteCommand handler methods
    
    @objc func handlePlayCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        GDLogRemoteManagerVerbose("<Play> command event")
        
        // If a device delegate is attached and it handles the play event, don't pass the event to the other delegate
        if let deviceDelegate = deviceDelegate, deviceDelegate.onRemotePlayCommand() {
            return .success
        }
        
        return handleEvent(.play) ? .success : .noSuchContent
    }
    
    @objc func handlePauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        GDLogRemoteManagerVerbose("<Pause> command event")
        
        // If a device delegate is attached and it handles the pause event, don't pass the event to the other delegate
        if let deviceDelegate = deviceDelegate, deviceDelegate.onRemotePauseCommand() {
            return .success
        }
        
        return handleEvent(.pause) ? .success : .noSuchContent
    }
    
    @objc func handleStopCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        GDLogRemoteManagerVerbose("<Stop> command event")

        return handleEvent(.stop) ? .success : .noSuchContent
    }
    
    @objc func handleTogglePlayPauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        GDLogRemoteManagerVerbose("<TogglePlayPause> command event")

        return handleEvent(.togglePlayPause) ? .success : .noSuchContent
    }
    
    @objc func handleNextTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        GDLogRemoteManagerVerbose("<Next> command event")

        return handleEvent(.nextTrack) ? .success : .noSuchContent
    }
    
    @objc func handlePreviousTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        GDLogRemoteManagerVerbose("<Previous> command event")

        return handleEvent(.previousTrack) ? .success : .noSuchContent
    }
    
    // MARK: Seek Command Handlers
    
    @objc func handleSeekForwardCommandEvent(_ event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        // There is a weird behavior when using the iOS Control Center to seek backwards - the `endSeeking`
        // event fires in the Seek Forward method. This can possibly happen because we use the iOS media
        // controls in a weird way (trying to seek without having media playing).
        if event.type == .endSeeking && didBeginSeekingBackwardEvent {
            return handleSeekBackwardCommandEvent(event)
        }
        
        defer {
            self.currentSeekForwardEvent = event
        }
        
        // Make sure that every `endSeeking` event has a `beginSeeking` event
        if event.type == .endSeeking && !didBeginSeekingForwardEvent {
            return .commandFailed
        }
       
        GDLogRemoteManagerVerbose("<Seek Forward : \(event.type == .beginSeeking ? "Begin" : "End")> command event")

        // We only act on `endSeeking` events
        guard event.type == .endSeeking else {
            return .noSuchContent
        }
       
        return handleEvent(.seekForward) ? .success : .noSuchContent
    }
    
    @objc func handleSeekBackwardCommandEvent(_ event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        defer {
            self.currentSeekBackwardEvent = event
        }
        
        // Make sure that every `endSeeking` event has a `beginSeeking` event
        if event.type == .endSeeking && !didBeginSeekingBackwardEvent {
            return .commandFailed
        }
        
        GDLogRemoteManagerVerbose("<Seek Backward : \(event.type == .beginSeeking ? "Begin" : "End")> command event")

        // We only act on `endSeeking` events
        guard event.type == .endSeeking else {
            return .noSuchContent
        }
        
        return handleEvent(.seekBackward) ? .success : .noSuchContent
    }

    // MARK: Handle Events

    private func handleEvent(_ event: RemoteCommand) -> Bool {
        // Disallow remote command events when in tutorial mode
        guard !AppContext.shared.isInTutorialMode else {
            GDLogRemoteManagerWarn("Dismissing remote command. App in tutorial mode.")
            return false
        }
        
        guard let delegate = delegate, delegate.remoteCommandManager(self, handle: event) else {
            AppContext.process(GlyphEvent(.invalidFunction))
            return false
        }
        
        return true
    }
    
}
