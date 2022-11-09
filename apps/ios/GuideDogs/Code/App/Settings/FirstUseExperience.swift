//
//  FirstUseExperience.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

// `FirstUseExperience` uses iOS `UserDefaults.standard` to track the completion
// of first-use experiences in the app
//
// A first-use experience is business logic of UX that should occur once across
// all sessions
class FirstUseExperience {
    
    // MARK: Enums
    
    enum Experience {
        // Define the first-use experiences
        case oobe
        case beaconTutorial
        case markerTutorial
        case previewTutorial
        case routeTutorial
        case iCloudBackup
        case previewRoadFinder
        case previewRoadFinderError
        // `.addDevice` captures which devices (represented by `DeviceType`)
        // have been added one or more times by the user
        case addDevice(device: DeviceType)
        // `Alert.deviceReachability` is displayed once per `DeviceType`
        case deviceReachabilityAlert(device: DeviceType)
        case share
        case donateSiriShortcuts
        // Captures whether the user has selected and listened to at least
        // one beacon of the given style (e.g., standard and haptic style)
        case oobeSelectBeacon(style: BeaconOption.Style)
        
        fileprivate var key: String {
            // Define a `UserDefaults` key for each first-use experience
            switch self {
            case .oobe: return "GDAFirstLaunchDidComplete"
            case .beaconTutorial: return "GDABeaconTutorialDidComplete"
            case .markerTutorial: return "GDAMarkerTutorialDidComplete"
            case .previewTutorial: return "GDAPreviewTutorialDidComplete"
            case .routeTutorial: return "GDARouteTutorialDidComplete"
            case .iCloudBackup: return "GDASettingsInitialCloudSyncCompleted"
            case .previewRoadFinder: return "GDASettingsPreviewInitialRoadFinderComplete"
            case .previewRoadFinderError: return "GDASettingsPreviewInitialRoadFinderError"
            case .addDevice(let device): return "GDADidAddDevice_" + device.rawValue
            case .deviceReachabilityAlert(let device): return "GDABannerDidDismissForKey_DeviceReachabilityAlert_" + device.rawValue
            case .share: return "GDAFirstUseExperienceShare"
            case .donateSiriShortcuts: return "GDAFirstUseExperienceDonateSiriShortcuts"
            case .oobeSelectBeacon(let style): return "GDAOOBEDidSelectBeacon_" + style.rawValue
            }
        }
    }
    
    // MARK: User Default Accessors
    
    static func didComplete(_ experience: Experience) -> Bool {
        // If there is no value for the key, `false` is returned
        return UserDefaults.standard.bool(forKey: experience.key)
    }
    
    static func setDidComplete(_ didComplete: Bool = true, for experience: Experience) {
        UserDefaults.standard.setValue(didComplete, forKey: experience.key)
    }
    
}
