//
//  OnboardingBehavior.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Notification.Name {
    static let onboardingDidComplete = Notification.Name("GDAOnboardingDidComplete")
}

class OnboardingBehavior: BehaviorBase {
    
    // MARK: Enums
    
    enum Context {
        case firstUse
        case help
    }
    
    // MARK: Properties
    
    let context: Context
    
    // MARK: Initialization
    
    init(context: Context) {
        self.context = context
        
        super.init(blockedAutoGenerators: [AutoCalloutGenerator.self, BeaconCalloutGenerator.self, IntersectionGenerator.self],
                   blockedManualGenerators: [AutoCalloutGenerator.self, BeaconCalloutGenerator.self] )
        
        manualGenerators.append(OnboardingGenerator())
    }
    
    override func activate(with parent: Behavior?) {
        super.activate(with: parent)
        
        let manager = AppContext.shared.spatialDataContext.destinationManager
        
        if manager.isAudioEnabled {
            // If there is an existing beacon, turn off beacon audio
            manager.toggleDestinationAudio(true)
        }
    }
    
    override func willDeactivate() {
        super.willDeactivate()
        
        guard context == .firstUse else {
            // If onboarding has already been completed,
            // no further actions are requied
            return
        }
        
        FirstUseExperience.setDidComplete(for: .oobe)
        
        // Track first app use
        SettingsContext.shared.appUseCount += 1
        
        // Play spatial audio if required services are authorized
        if AppContext.shared.geolocationManager.isAuthorized && AppContext.shared.motionActivityContext.isAuthorized {
            // Play app launch sound
            AppContext.process(GlyphEvent(.appLaunch))
            
            // Start a `My Location` callout
            AppContext.process(ExplorationModeToggled(.locate, logContext: "first_launch"))
        }
        
        // Post notification
        NotificationCenter.default.post(name: .onboardingDidComplete, object: self)
    }
    
}

struct OnboardingExampleCalloutEvent: UserInitiatedEvent {
    var completion: ((Bool) -> Void)?
}

struct StartSelectedBeaconAudioEvent: UserInitiatedEvent { }
struct StopSelectedBeaconAudioEvent: UserInitiatedEvent { }

struct SelectedBeaconCalloutEvent: UserInitiatedEvent {
    var completion: ((Bool) -> Void)?
}

struct SelectedBeaconOrientationCalloutEvent: UserInitiatedEvent {
    var isAhead: Bool
}
