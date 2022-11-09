//
//  SettingsContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation

extension Notification.Name {
    static let automaticCalloutsEnabledChanged = Notification.Name("GDAAutomaticCalloutsChanged")
    static let autoCalloutCategorySenseChanged = Notification.Name("GDAAutomaticCalloutSenseChanged")
    static let beaconVolumeChanged = Notification.Name("GDABeaconVolumeChanged")
    static let ttsVolumeChanged = Notification.Name("GDATTSVolumeChanged")
    static let otherVolumeChanged = Notification.Name("GDAOtherVolumeChanged")
    static let beaconGainChanged = Notification.Name("GDABeaconGainChanged")
    
    static let previewIntersectionsIncludeUnnamedRoadsDidChange = Notification.Name("PreviewIntersectionsIncludeUnnamedRoadsDidChange")
}

class SettingsContext {
    
    struct Keys {
        // MARK: Internal UserDefaults Keys
        
        /// Number of times the user has open the app
        fileprivate static let appUseCount               = "GDAAppUseCount"
        fileprivate static let newFeaturesLastDisplayedVersion = "GDANewFeaturesLastDisplayedVersion"
        fileprivate static let clientIdentifier          = "GDAUserDefaultClientIdentifier"
        fileprivate static let metricUnits               = "GDASettingsMetric"
        fileprivate static let locale                    = "GDASettingsLocaleIdentifier"
        fileprivate static let voiceID                   = "GDAAppleSynthVoice"
        fileprivate static let speakingRate              = "GDASettingsSpeakingRate"
        fileprivate static let beaconVolume              = "GDABeaconVolume"
        fileprivate static let ttsVolume                 = "GDATTSVolume"
        fileprivate static let otherVolume               = "GDAOtherVolume"
        fileprivate static let telemetryOptout           = "GDASettingsTelemetryOptout"
        fileprivate static let selectedBeaconName        = "GDASelectedBeaconName"
        fileprivate static let useOldBeacon              = "GDASettingsUseOldBeacon"
        fileprivate static let playBeaconStartEndMelody  = "GDAPlayBeaconStartEndMelody"
        fileprivate static let automaticCalloutsEnabled  = "GDASettingsAutomaticCalloutsEnabled"
        fileprivate static let sensePlace                = "GDASettingsPlaceSenseEnabled"
        fileprivate static let senseLandmark             = "GDASettingsLandmarkSenseEnabled"
        fileprivate static let senseMobility             = "GDASettingsMobilitySenseEnabled"
        fileprivate static let senseInformation          = "GDASettingsInformationSenseEnabled"
        fileprivate static let senseSafety               = "GDASettingsSafetySenseEnabled"
        fileprivate static let senseIntersection         = "GDASettingsIntersectionsSenseEnabled"
        fileprivate static let senseDestination          = "GDASettingsDestinationSenseEnabled"
        fileprivate static let apnsDeviceToken           = "GDASettingsAPNsDeviceToken"
        fileprivate static let pushNotificationTags      = "GDASettingsPushNotificationTags"
        fileprivate static let previewIntersectionsIncludeUnnamedRoads = "GDASettingsPreviewIntersectionsIncludeUnnamedRoads"
        fileprivate static let audioSessionMixesWithOthers = "GDAAudioSessionMixesWithOthers"
        fileprivate static let markerSortStyle           = "GDAMarkerSortStyle"
        
        fileprivate static let ttsGain = "GDATTSAudioGain"
        fileprivate static let beaconGain = "GDABeaconAudioGain"
        fileprivate static let afxGain = "GDAAFXAudioGain"
        
        // MARK: Notification Keys
        
        static let enabled = "GDAEnabled"
    }
    
    // MARK: Shared Instance
    
    static let shared = SettingsContext()
    
    // MARK: User Defaults
    
    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    // MARK: Initialization
    
    init() {
        // register default values
        userDefaults.register(defaults: [
            Keys.appUseCount: 0,
            Keys.newFeaturesLastDisplayedVersion: "0.0.0",
            Keys.metricUnits: Locale.current.usesMetricSystem,
            Keys.speakingRate: 0.55,
            Keys.beaconVolume: 0.75,
            Keys.ttsVolume: 0.75,
            Keys.otherVolume: 0.75,
            Keys.ttsGain: 5,
            Keys.beaconGain: 5,
            Keys.afxGain: 5,
            Keys.telemetryOptout: (BuildSettings.configuration != .release),
            Keys.selectedBeaconName: V2Beacon.description,
            Keys.useOldBeacon: false,
            Keys.playBeaconStartEndMelody: false,
            Keys.automaticCalloutsEnabled: true,
            Keys.sensePlace: true,
            Keys.senseLandmark: true,
            Keys.senseMobility: true,
            Keys.senseInformation: true,
            Keys.senseSafety: true,
            Keys.senseIntersection: true,
            Keys.senseDestination: true,
            Keys.previewIntersectionsIncludeUnnamedRoads: false,
            Keys.audioSessionMixesWithOthers: true,
            Keys.markerSortStyle: SortStyle.distance.rawValue
        ])
        
        resetLocaleIfNeeded()
    }
    
    private func resetLocaleIfNeeded() {
        // If the user has selected a locale in the first launch experience, but did not finish the first
        // launch experience and terminated the app half way, reset the chosen locale when re-opening the app.
        if !FirstUseExperience.didComplete(.oobe) && locale != nil {
            locale = nil
        }
    }
    
    // MARK: Properties

    var appUseCount: Int {
        get {
            return userDefaults.integer(forKey: Keys.appUseCount)
        } set {
            userDefaults.set(newValue, forKey: Keys.appUseCount)
        }
    }
    
    var newFeaturesLastDisplayedVersion: String {
        get {
            guard let versionString = userDefaults.string(forKey: Keys.newFeaturesLastDisplayedVersion) else {
                userDefaults.set("0.0.0", forKey: Keys.newFeaturesLastDisplayedVersion)
                return "0.0.0"
            }
            
            return versionString
        }
        set {
            userDefaults.set(newValue, forKey: Keys.newFeaturesLastDisplayedVersion)
        }
    }
    
    var clientId: String {
        get {
            if let clientId = userDefaults.string(forKey: Keys.clientIdentifier) {
                return clientId
            } else {
                let clientId = UUID().uuidString
                userDefaults.set(clientId, forKey: Keys.clientIdentifier)
                return clientId
            }
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.clientIdentifier)
        }
    }
    
    var metricUnits: Bool {
        get {
            return userDefaults.bool(forKey: Keys.metricUnits)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.metricUnits)
        }
    }
    
    /// Cache settings `locale`, as it seems to be expensive to create.
    private var _locale: Locale?
    
    var locale: Locale? {
        get {
            guard let identifier = userDefaults.string(forKey: Keys.locale) else { return nil }
            
            if let locale = _locale, locale.identifier == identifier {
                return locale
            }
            
            let locale = Locale(identifier: identifier)
            _locale = locale
            
            return locale
        }
        set(newValue) {
            if let newValue = newValue {
                userDefaults.set(newValue.identifier, forKey: Keys.locale)
            } else {
                userDefaults.removeObject(forKey: Keys.locale)
            }
        }
    }
    
    var speakingRate: Float {
        get {
            return userDefaults.float(forKey: Keys.speakingRate)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.speakingRate)
        }
    }
    
    var beaconVolume: Float {
        get {
            return userDefaults.float(forKey: Keys.beaconVolume)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.beaconVolume)
            NotificationCenter.default.post(name: .beaconVolumeChanged, object: nil)
        }
    }
    
    var ttsVolume: Float {
        get {
            return userDefaults.float(forKey: Keys.ttsVolume)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.ttsVolume)
            NotificationCenter.default.post(name: .ttsVolumeChanged, object: nil)
        }
    }
    
    var otherVolume: Float {
        get {
            return userDefaults.float(forKey: Keys.otherVolume)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.otherVolume)
            NotificationCenter.default.post(name: .otherVolumeChanged, object: nil)
        }
    }
    
    var ttsGain: Float {
        get {
            return userDefaults.float(forKey: Keys.ttsGain)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.ttsGain)
        }
    }
    
    var beaconGain: Float {
        get {
            return userDefaults.float(forKey: Keys.beaconGain)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.beaconGain)
            NotificationCenter.default.post(name: .beaconGainChanged, object: nil)
        }
    }
    
    var afxGain: Float {
        get {
            return userDefaults.float(forKey: Keys.afxGain)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.afxGain)
        }
    }
    
    var telemetryOptout: Bool {
        get {
            return userDefaults.bool(forKey: Keys.telemetryOptout)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.telemetryOptout)
        }
    }
    
    var previewIntersectionsIncludeUnnamedRoads: Bool {
        get {
            return userDefaults.bool(forKey: Keys.previewIntersectionsIncludeUnnamedRoads)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.previewIntersectionsIncludeUnnamedRoads)
            
            NotificationCenter.default.post(name: .previewIntersectionsIncludeUnnamedRoadsDidChange, object: self, userInfo: [Keys.enabled: newValue])
        }
    }
    
    var audioSessionMixesWithOthers: Bool {
        get {
            return userDefaults.bool(forKey: Keys.audioSessionMixesWithOthers)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.audioSessionMixesWithOthers)
        }
    }
    
    // MARK: Audio Beacon
    
    var selectedBeacon: String {
        get {
            if let selected = userDefaults.string(forKey: Keys.selectedBeaconName) {
                return selected
            }
            
            // If the user hasn't selected a new beacon yet, default to the beacon they previously used
            if userDefaults.bool(forKey: Keys.useOldBeacon) {
                return ClassicBeacon.description
            } else {
                return V2Beacon.description
            }
        }
        set {
            userDefaults.set(newValue, forKey: Keys.selectedBeaconName)
        }
    }
    
    var playBeaconStartAndEndMelodies: Bool {
        get {
            return userDefaults.bool(forKey: Keys.playBeaconStartEndMelody)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.playBeaconStartEndMelody)
        }
    }
    
    // MARK: Push Notifications

    var apnsDeviceToken: Data? {
        get {
            return userDefaults.data(forKey: Keys.apnsDeviceToken)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.apnsDeviceToken)
        }
    }
    
    var pushNotificationTags: Set<String>? {
        get {
            guard let array = userDefaults.array(forKey: Keys.pushNotificationTags) as? [String] else { return nil }
            return Set(array)
        }
        set(newValue) {
            if let newValue = newValue {
                userDefaults.set(Array(newValue), forKey: Keys.pushNotificationTags)
            } else {
                userDefaults.removeObject(forKey: Keys.pushNotificationTags)
            }
        }
    }
    
    // MARK: Apple TTS
    
    var voiceId: String? {
        get {
            return userDefaults.string(forKey: Keys.voiceID)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.voiceID)
        }
    }
    
    // MARK: Markers and Routes List
    
    var defaultMarkerSortStyle: SortStyle {
        get {
            guard let sortString = userDefaults.string(forKey: Keys.markerSortStyle),
                  let sort = SortStyle(rawValue: sortString) else {
                return SortStyle.distance
            }
            
            return sort
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.markerSortStyle)
        }
    }
    
}

extension SettingsContext: AutoCalloutSettingsProvider {
    var automaticCalloutsEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.automaticCalloutsEnabled)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.automaticCalloutsEnabled)
            
            NotificationCenter.default.post(name: .automaticCalloutsEnabledChanged, object: self, userInfo: [Keys.enabled: newValue])
        }
    }
    
    var placeSenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.sensePlace)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.sensePlace)
            NotificationCenter.default.post(name: .autoCalloutCategorySenseChanged, object: self)
        }
    }
    
    var landmarkSenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.senseLandmark)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.senseLandmark)
            NotificationCenter.default.post(name: .autoCalloutCategorySenseChanged, object: self)
        }
    }
    
    var mobilitySenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.senseMobility)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.senseMobility)
            NotificationCenter.default.post(name: .autoCalloutCategorySenseChanged, object: self)
        }
    }
    
    var informationSenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.senseInformation)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.senseInformation)
            NotificationCenter.default.post(name: .autoCalloutCategorySenseChanged, object: self)
        }
    }
    
    var safetySenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.senseSafety)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.senseSafety)
            NotificationCenter.default.post(name: .autoCalloutCategorySenseChanged, object: self)
        }
    }
    
    var intersectionSenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.senseIntersection)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.senseIntersection)
        }
    }
    
    var destinationSenseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.senseDestination)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.senseDestination)
        }
    }
}
