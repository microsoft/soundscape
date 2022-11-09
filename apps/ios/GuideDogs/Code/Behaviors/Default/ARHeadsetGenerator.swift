//
//  ARHeadsetGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class HeadsetConnectionEvent: StateChangedEvent {
    enum State {
        case reconnected, disconnected, firstConnection
    }
    
    var name: String {
        return "HeadsetConnection.\(state).\(headsetName)"
    }
    
    let headsetName: String
    let state: State
    
    init(_ headsetName: String, state: State) {
        self.headsetName = headsetName
        self.state = state
    }
}

class HeadsetCalibrationEvent: StateChangedEvent {
    let headsetName: String
    let deviceType: DeviceType
    let callout: String
    let state: DeviceCalibrationState
    
    init(_ headsetName: String,
         deviceType: DeviceType,
         callout: String,
         state: DeviceCalibrationState) {
        self.headsetName = headsetName
        self.deviceType = deviceType
        self.callout = callout
        self.state = state
    }
}

class CalibrationOverrideEvent: StateChangedEvent { }

extension CalloutOrigin {
    static let arHeadset = CalloutOrigin(rawValue: "ar_headset", localizedString: GDLocalizationUnnecessary("AR HEADSET"))!
}

class ARHeadsetGenerator: AutomaticGenerator {
    private var calibrationPlayerId: AudioPlayerIdentifier?
    
    private var previousCalibrationState = DeviceCalibrationState.needsCalibrating
    
    private var calibrationOverriden = false
    
    /// This property is used for tracking if the audio beacon was enabled before the calibration audio started. If
    /// it was, then the beacon should be toggled back on when the calibration audio is turned off.
    private var previousBeaconAudioEnabled = false
    
    let canInterrupt = false
    
    func cancelCalloutsForEntity(id: String) {
        // No-op: This generator only responds to events regarding AR headsets and not POIs or locations
    }
    
    func respondsTo(_ event: StateChangedEvent) -> Bool {
        return event is HeadsetConnectionEvent || event is HeadsetCalibrationEvent || event is CalibrationOverrideEvent
    }
    
    func handle(event: StateChangedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let event as HeadsetConnectionEvent:
            // Any connection event will reset the calibration override state
            calibrationOverriden = false
            
            guard let callouts = processConnectionEvent(event) else {
                return nil
            }
            
            return .playCallouts(callouts)
            
        case let event as HeadsetCalibrationEvent:
            guard let callouts = processCalibrationEvent(event) else {
                return nil
            }
            
            return .playCallouts(callouts)
            
        case is CalibrationOverrideEvent:
            // Override the calibration
            stopCalibrationTrack()
            calibrationOverriden = true
            
            // Don't do any callouts when the calibration is overriden
            return .noAction
            
        default:
            return nil
        }
    }
    
    private func processConnectionEvent(_ event: HeadsetConnectionEvent) -> CalloutGroup? {
        switch event.state {
        case .firstConnection:
            let earcon = GlyphCallout(.arHeadset, .connectionSuccess)
            return CalloutGroup([earcon], logContext: "ar_headset")
            
        case .reconnected:
            let callout = StringCallout(.arHeadset, GDLocalizedString("devices.callouts.connected", event.headsetName))
            let earcon = GlyphCallout(.arHeadset, .connectionSuccess)
            return CalloutGroup([earcon, callout], logContext: "ar_headset")
            
        case .disconnected:
            previousCalibrationState = .needsCalibrating
            stopCalibrationTrack()
            
            let callout = StringCallout(.arHeadset, GDLocalizedString("devices.callouts.disconnected", event.headsetName))
            let earcon = GlyphCallout(.arHeadset, .invalidFunction)
            return CalloutGroup([earcon, callout], logContext: "ar_headset")
        }
    }
    
    private func processCalibrationEvent(_ event: HeadsetCalibrationEvent) -> CalloutGroup? {
        defer {
            previousCalibrationState = event.state
        }
        
        // Doing this check after defer allows us to still track the calibration state
        guard !calibrationOverriden else {
            if event.state == .calibrated && (previousCalibrationState == .calibrating || previousCalibrationState == .needsCalibrating) {
                return CalloutGroup([GlyphCallout(.arHeadset, .calibrationSuccess)], playModeSounds: false, stopSoundsBeforePlaying: false, logContext: "ar_headset")
            } else {
                return nil
            }
        }
        
        var callouts: CalloutGroup?
        var needsCalibratingCalloutString: String
        
        switch event.deviceType {
        default:
            needsCalibratingCalloutString = GDLocalizedString("devices.callouts.needs_calibration")
        }
        
        switch (previousCalibrationState, event.state) {
        case (.needsCalibrating, .calibrating): // Calibration has started
            callouts = CalloutGroup([StringCallout(.arHeadset, needsCalibratingCalloutString)], logContext: "ar_headset")
            callouts?.onStart = self.startCalibrationTrack
            callouts?.isValid = ARHeadsetGenerator.shouldPlayCalibrationStartedCallouts
            
        case (.calibrating, .calibrated): // Calibration has ended
            let callout = StringCallout(.arHeadset, GDLocalizedString("devices.callouts.calibrated"))
            let earcon = GlyphCallout(.arHeadset, .calibrationSuccess)
            
            callouts = CalloutGroup([earcon, callout], logContext: "ar_headset")
            callouts?.onStart = self.stopCalibrationTrack
            callouts?.isValid = ARHeadsetGenerator.shouldPlayCalibrationEndCallouts
            
        case (.calibrated, .calibrating): // Device needs to be recalibrated
            let callout = StringCallout(.arHeadset, needsCalibratingCalloutString)
            
            callouts = CalloutGroup([callout], logContext: "ar_headset")
            callouts?.onStart = self.startCalibrationTrack
            callouts?.isValid = ARHeadsetGenerator.shouldPlayCalibrationStartedCallouts
            
        case (.needsCalibrating, .calibrated): // Device was already calibrated
            let callout = StringCallout(.arHeadset, GDLocalizedString("devices.callouts.calibrated"))
            let earcon = GlyphCallout(.arHeadset, .calibrationSuccess)
            callouts = CalloutGroup([earcon, callout], logContext: "ar_headset")
            callouts?.isValid = ARHeadsetGenerator.shouldPlayCalibrationEndCallouts
            
        default:
            return nil
        }
        
        return callouts
    }
    
    private func startCalibrationTrack() {
        guard let id = AppContext.shared.audioEngine.play(looped: GenericSound(.calibrationInProgress)) else {
            return
        }
        
        previousBeaconAudioEnabled = AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled
        
        if previousBeaconAudioEnabled {
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
        }
        
        calibrationPlayerId = id
    }
    
    private func stopCalibrationTrack() {
        guard let id = calibrationPlayerId else {
            return
        }
        
        if previousBeaconAudioEnabled {
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
            previousBeaconAudioEnabled = false
        }
        
        calibrationPlayerId = nil
        AppContext.shared.audioEngine.stop(id)
    }
    
}

// MARK: - Helpers

extension ARHeadsetGenerator {
    
    private static func shouldPlayCalibrationStartedCallouts() -> Bool {
        guard let device = AppContext.shared.deviceManager.devices.first as? CalibratableDevice, device.isConnected else { return false }
        return device.calibrationState != .calibrated
    }
    
    private static func shouldPlayCalibrationEndCallouts() -> Bool {
        guard let device = AppContext.shared.deviceManager.devices.first as? CalibratableDevice, device.isConnected else { return false }
        return device.calibrationState == .calibrated
    }
    
}
