//
//  OnboardingGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class OnboardingGenerator: ManualGenerator {
    
    private let beaconDemo = BeaconDemoHelper()
    
    private var eventTypes: [UserInitiatedEvent.Type] = [
        OnboardingExampleCalloutEvent.self,
        StartSelectedBeaconAudioEvent.self,
        StopSelectedBeaconAudioEvent.self,
        SelectedBeaconCalloutEvent.self,
        SelectedBeaconOrientationCalloutEvent.self
    ]
    
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let event as OnboardingExampleCalloutEvent:
            return .playCallouts(getExampleCallouts(completion: event.completion))
            
        case is StartSelectedBeaconAudioEvent:
            guard let userLocation = AppContext.shared.geolocationManager.location else {
                return nil
            }
            
            guard let heading = AppContext.shared.geolocationManager.presentationHeading.value else {
                return nil
            }
            
            guard let beacon = BeaconOption(id: SettingsContext.shared.selectedBeacon) else {
                return nil
            }
            
            // Prepare demo
            beaconDemo.prepare()
            
            // Place beacon 100m away and at a bearing defined by the beacon's style
            let location = CLLocation(userLocation.coordinate.destination(distance: 100.0, bearing: heading.add(degrees: beacon.style.defaultBearing)))
            beaconDemo.play(shouldTimeOut: false, newBeaconLocation: location, logContext: "onboarding")
            
            return .noAction
            
        case is StopSelectedBeaconAudioEvent:
            // Stop and remove beacon
            beaconDemo.restoreState(logContext: "onboarding")
            
            return .noAction
            
        case let event as SelectedBeaconCalloutEvent:
            guard let group = getBeaconCallouts(completion: event.completion) else {
                event.completion?(false)
                return .noAction
            }
            
            return .playCallouts(group)
            
        case let event as SelectedBeaconOrientationCalloutEvent:
            guard let callouts = getBeaconOrientationCallouts(isAhead: event.isAhead) else {
                return nil
            }
            
            return .playCallouts(callouts)
            
        default:
            return nil
        }
    }
    
    // MARK: Callouts
    
    private func getExampleCallouts(completion: ((Bool) -> Void)?) -> CalloutGroup {
        let callouts: [CalloutProtocol] = [
            GlyphCallout(.onboarding, .enterMode),
            
            RelativeGlyphCallout(.onboarding, .poiSense, position: 90.0),
            RelativeStringCallout(.onboarding, GDLocalizedString("first_launch.callouts.example.1"), position: 90.0),
            
            RelativeGlyphCallout(.onboarding, .poiSense, position: 270.0),
            RelativeStringCallout(.onboarding, GDLocalizedString("osm.tag.bus_stop"), position: 270.0),
            
            RelativeGlyphCallout(.onboarding, .mobilitySense, position: 0.0),
            RelativeStringCallout(.onboarding, GDLocalizedString("preview.approaching_intersection.label"), position: 0.0),
            RelativeStringCallout(.onboarding, GDLocalizedString("first_launch.callouts.example.3"), position: 270.0),
            RelativeStringCallout(.onboarding, GDLocalizedString("first_launch.callouts.example.4"), position: 90.0),
            
            GlyphCallout(.onboarding, .exitMode)
        ]
        
        let group = CalloutGroup(callouts, logContext: "onboarding.callouts")
        group.onComplete = completion
        
        return group
    }
    
    private func getCurrentBearingToBeacon(userLocation: CLLocation, beacon: ReferenceEntity) -> Double? {
        guard let heading = AppContext.shared.geolocationManager.presentationHeading.value else {
            return nil
        }
        
        guard let bearingToLocation = AppContext.shared.spatialDataContext.destinationManager.destination?.bearingToClosestLocation(from: userLocation) else {
            return nil
        }
        
        return bearingToLocation - heading
    }
    
    private func getBeaconCallouts(completion: ((Bool) -> Void)?) -> CalloutGroup? {
        guard let beacon = BeaconOption(id: SettingsContext.shared.selectedBeacon) else {
            return nil
        }
        
        guard let marker = AppContext.shared.spatialDataContext.destinationManager.destination else {
            return nil
        }
        
        guard !FirstUseExperience.didComplete(.oobeSelectBeacon(style: beacon.style)) else {
            // Callouts will occur the first time that the user selects a beacon of the given
            // style
            return nil
        }
        
        // Log completion
        FirstUseExperience.setDidComplete(for: .oobeSelectBeacon(style: beacon.style))
        
        let callouts: [CalloutProtocol] = [GenericCallout(.onboarding, soundsBuilder: { location, _, _ in
            guard let location = location else {
                return []
            }
            
            let localizedString: String
            
            switch beacon.style {
            case .standard: localizedString = GDLocalizedString("first_launch.beacon.callout.headtracking.standard")
            case .haptic: localizedString = GDLocalizedString("first_launch.beacon.callout.headtracking.haptic")
            }
            
            return [TTSSound(localizedString, at: marker.closestLocation(from: location))]
        })]
        
        let group = CalloutGroup(callouts, logContext: "onboarding.beacon.first_selection")
        group.onComplete = completion
        
        return group
    }
    
    private func getBeaconOrientationCallouts(isAhead: Bool) -> CalloutGroup? {
        guard let beacon = BeaconOption(id: SettingsContext.shared.selectedBeacon) else {
            return nil
        }
        
        guard beacon.isOrientationCalloutsEnabled(isAhead: isAhead) else {
            return nil
        }
        
        guard let marker = AppContext.shared.spatialDataContext.destinationManager.destination else {
            return nil
        }
        
        let callouts: [CalloutProtocol] = [GenericCallout(.onboarding, soundsBuilder: { location, _, _ in
            guard let location = location else {
                return []
            }
            
            let localizedString = isAhead ? GDLocalizedString("first_launch.beacon.callout.ahead") : GDLocalizedString("first_launch.beacon.callout.behind")
            return [TTSSound(localizedString, at: marker.closestLocation(from: location))]
        })]
        
        return CalloutGroup(callouts, action: .clear, logContext: "onboarding.beacon.orientation")
    }
    
}

private extension BeaconOption {
    
    func isOrientationCalloutsEnabled(isAhead: Bool) -> Bool {
        if isAhead {
            // Ahead callouts are enabled for all beacons
            return true
        } else {
            switch self {
            case .original, .tacticle, .flare:
                return true
            case .pulse:
                // Behind callout is not enabled for pulse
                return false
            default:
                // Callouts for other beacons are not enabled
                return false
            }
        }
    }
    
}

private extension BeaconOption.Style {
    
    var defaultBearing: Double {
        switch self {
        case .standard: return 45.0
        case .haptic: return 0.0
        }
    }
    
}
