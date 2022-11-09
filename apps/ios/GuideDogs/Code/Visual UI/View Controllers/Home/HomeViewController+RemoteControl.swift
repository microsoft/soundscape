//
//  HomeViewController+RemoteControl.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

private var isRepeating = false

extension HomeViewController: RemoteCommandManagerDelegate {
    
    func remoteCommandManager(_ remoteCommandManager: RemoteCommandManager, handle event: RemoteCommand) -> Bool {
        GDATelemetry.track("remote_command.\(event.rawValue)")
        
        // Disallow remote command events when in sleep/snooze mode
        guard AppContext.shared.state == .normal else {
            return false
        }
        
        if let route = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance {
            switch event {
            case .play, .pause, .stop, .togglePlayPause:
                return AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio(automatic: false)
            case .nextTrack, .seekForward:
                route.nextWaypoint()
                return true
            case .previousTrack, .seekBackward:
                route.previousWaypoint()
                return true
            }
        }
        
        switch event {
        case .play, .pause, .stop, .togglePlayPause:
            return handleToggleAudio()
        case .nextTrack:
            return handleMyLocation()
        case .previousTrack:
            return handleRepeat()
        case .seekForward:
            return handleToggleCallouts()
        case .seekBackward:
            return handleAroundMe()
        }
    }
    
    private func handleToggleAudio() -> Bool {
        return AppContext.shared.eventProcessor.toggleAudio()
    }
    
    private func handleMyLocation() -> Bool {
        NotificationCenter.default.post(name: Notification.Name.didToggleLocate, object: self)
        return true
    }
    
    private func handleRepeat() -> Bool {
        guard !isRepeating else {
            AppContext.shared.eventProcessor.hush(playSound: false)
            isRepeating = false
            return true
        }
        
        guard let callout = AppContext.shared.calloutHistory.callouts.last else {
            return false
        }
        
        isRepeating = true

        AppContext.process(RepeatCalloutEvent(callout: callout) { (_) in
            isRepeating = false
        })
        
        return true
    }
    
    private func handleToggleCallouts() -> Bool {
        AppContext.process(ToggleAutoCalloutsEvent(playSound: true))
        
        GDATelemetry.track("settings.allow_callouts", value: String(SettingsContext.shared.automaticCalloutsEnabled))
        
        // Play announcement
        AppContext.shared.audioEngine.stopDiscrete()
        let announcement = SettingsContext.shared.automaticCalloutsEnabled ? GDLocalizedString("callouts.callouts_on") : GDLocalizedString("callouts.callouts_off")
        AppContext.process(GenericAnnouncementEvent(announcement))
        return true
    }
    
    private func handleAroundMe() -> Bool {
        NotificationCenter.default.post(name: Notification.Name.didToggleOrientate, object: self)
        return true
    }
}
