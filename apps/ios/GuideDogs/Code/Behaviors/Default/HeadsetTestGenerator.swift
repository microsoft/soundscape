//
//  HeadsetTestGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class HeadsetTestEvent: UserInitiatedEvent {
    enum State {
        case start, end
    }
    
    var state: State
    
    init(_ state: State) {
        self.state = state
    }
}

extension CalloutOrigin {
    static let arHeadsetTest = CalloutOrigin(rawValue: "ar_headset_test", localizedString: GDLocalizationUnnecessary("AR HEADSET TEST"))!
}

class HeadsetTestGenerator: ManualGenerator {
    
    private var beaconPlayerId: AudioPlayerIdentifier?
    
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        return event is HeadsetTestEvent
    }
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        guard let event = event as? HeadsetTestEvent else {
            return nil
        }
        
        switch event.state {
        case .start:
            
            // Play the instruction callout and then start the beacon
            let callouts = CalloutGroup([StringCallout(.arHeadsetTest, GDLocalizedString("devices.test_headset.callout"))], action: .interruptAndClear, logContext: "ar_headset")
            callouts.onStart = self.setBeacon
            
            return .playCallouts(callouts)
            
        case .end:
            clearBeacon()
            return .noAction
        }
    }
    
    private func setBeacon() {
        let heading = AppContext.shared.geolocationManager.presentationHeading
        
        guard let location = AppContext.shared.geolocationManager.location, let headingVal = heading.value else {
            return
        }
        
        // If there is an existing beacon, mute it
        if AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled {
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio()
        }
        
        // Calculate beacon location
        let direction = headingVal.add(degrees: 100)
        let beaconLocation = CLLocation(location.coordinate.destination(distance: 100, bearing: direction))
        
        switch SettingsContext.shared.selectedBeacon {
        case V2Beacon.description: playBeacon(V2Beacon.self, at: beaconLocation)
        case FlareBeacon.description: playBeacon(FlareBeacon.self, at: beaconLocation)
        case ShimmerBeacon.description: playBeacon(ShimmerBeacon.self, at: beaconLocation)
        case TactileBeacon.description: playBeacon(TactileBeacon.self, at: beaconLocation)
        case PingBeacon.description: playBeacon(PingBeacon.self, at: beaconLocation)
        case DropBeacon.description: playBeacon(DropBeacon.self, at: beaconLocation)
        case SignalBeacon.description: playBeacon(SignalBeacon.self, at: beaconLocation)
        case SignalSlowBeacon.description: playBeacon(SignalSlowBeacon.self, at: beaconLocation)
        case SignalVerySlowBeacon.description: playBeacon(SignalVerySlowBeacon.self, at: beaconLocation)
        case MalletBeacon.description: playBeacon(MalletBeacon.self, at: beaconLocation)
        case MalletSlowBeacon.description: playBeacon(MalletSlowBeacon.self, at: beaconLocation)
        case MalletVerySlowBeacon.description: playBeacon(MalletVerySlowBeacon.self, at: beaconLocation)
        default:
            // Always default to the V1 beacon
            playBeacon(ClassicBeacon.self, at: beaconLocation)
        }
    }
    
    /// Generic helper function for creating a beacon sound and passing it to the audio engine given a DynamicAudioEngineAsset type
    ///
    /// - Parameters:
    ///   - assetType: Asset type to create a beacon sound for
    ///   - args: Beacon settings
    private func playBeacon<T: DynamicAudioEngineAsset>(_ assetType: T.Type, at location: CLLocation) {
        guard let sound = BeaconSound(assetType, at: location) else {
            GDLogAppError("Beacon sound failed to load!")
            return
        }
        
        beaconPlayerId = AppContext.shared.audioEngine.play(sound)
    }
    
    private func clearBeacon() {
        guard let id = beaconPlayerId else {
            return
        }
        
        AppContext.shared.audioEngine.stop(id)
        beaconPlayerId = nil
    }
    
}
