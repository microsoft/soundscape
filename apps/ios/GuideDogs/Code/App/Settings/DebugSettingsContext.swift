//
//  DebugSettingsContext.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import MapKit.MKTypes

extension Notification.Name {
    static let isHeadphoneMotionEnabledDidChange = Notification.Name("GDAIsHeadphoneMotionEnabledDidChange")
}

class DebugSettingsContext {
    
    // MARK: Keys
    
    private struct UserDefaultKeys {
        static let ShowLogConsole = "GDAShowLogConsole"
        static let Loggers = "GDALoggers"
        static let Theme = "Theme"
        static let LocationAccuracy = "GDALocationAccuracy"
        static let IsUsingHeading = "GDAUsingHeading"
        
        static let EnvRenderingAlgorithm = "GDA3DRenderingAlgorithm"
        static let EnvRenderingDistance = "GDA3DRenderingDistance"
        static let EnvRenderingReverbEnable = "GDA3DRenderingReverbEnable"
        static let EnvRenderingReverbPreset = "GDA3DRenderingReverbPreset"
        static let EnvRenderingReverbBlend = "GDA3DRenderingReverbBlend"
        static let EnvRenderingReverbLevel = "GDA3DRenderingReverbLevel"
        static let EnvReverbFilterActive = "GDA3DReverbFilterActive"
        static let EnvReverbFilterBandwidth = "GDA3DReverbFilterBandwidth"
        static let EnvReverbFilterBypass = "GDA3DReverbFilterBypass"
        static let EnvReverbFilterType = "GDA3DReverbFilterType"
        static let EnvReverbFilterFrequency = "GDA3DReverbFilterFrequency"
        static let EnvReverbFilterGain = "GDA3DReverbFilterGain"
        
        static let MapType = "GDAMapType"

        static let MapFilterShowExcluded = "GDAMapFilterShowExcluded"
        static let MapFilterPlaces = "GDAMapFilterPlaces"
        static let MapFilterLandmarks = "GDAMapFilterLandmarks"
        static let MapFilterMobility = "GDAMapFilterMobility"
        static let MapFilterInformation = "GDAMapFilterInformation"
        static let MapFilterSafety = "GDAMapFilterSafety"
        static let MapFilterObjects = "GDAMapFilterObjects"
        static let MapFilterIntersections = "GDAMapFilterIntersections"
        static let MapFilterFootprints = "GDAMapFilterFootprints"
        
        static let GPXSimulationAudioEnabled = "GDASimulationAudioEnabled"
        static let GPXSimulationAudioPauseWithSimulation = "GDASimulationAudioPauseWithSimulation"
        static let GPXSimulationAudioVolume = "GDASimulationAudioVolume"
        
        static let ServicesHostName = "GDAServicesHostName"
        static let AssetsHostName = "GDAAssetsHostName"
        
        static let cacheDuration = "GDACacheDuration"
        
        static let isHeadphoneMotionEnabled = "GDAIsHeadphoneMotionEnabled"
        static let isHeadphoneMotionVerboseLoggingEnabled = "GDAIsHeadphoneMotionVerboseLoggingEnabled"
        static let isHeadphoneMotionDeviceHeadingEnabled = "GDAIsHeadphoneMotionDeviceHeadingEnabled"
        static let isHeadphoneMotionCourseEnabled = "GDAIsHeadphoneMotionCourseEnabled"
        
        static let doubleLocalizedStrings = "NSDoubleLocalizedStrings"
        static let boundedPseudolanguage = "NSSurroundLocalizedStrings"
        
        static let localPushNotification1TimeInternal = "GDALocalPushNotification1TimeInternal"
        static let localPushNotification2TimeInternal = "GDALocalPushNotification2TimeInternal"
        
        static let presentSurveyAlert = "GDAPresentSurveyAlert"
    }
    
    // MARK: Shared Instance
    
    static let shared = DebugSettingsContext()

    // MARK: User Defaults
    
    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }

    // MARK: Initialization
    
    init() {
        // Set the nearby places map filter to all be on - setting them off removes the corresponding POIs from the map
        // Set default location accuracy to be "best for navigation"
        userDefaults.register(defaults: [
            UserDefaultKeys.MapType: Int(MKMapType.standard.rawValue),
            UserDefaultKeys.MapFilterPlaces: true,
            UserDefaultKeys.MapFilterLandmarks: true,
            UserDefaultKeys.MapFilterMobility: true,
            UserDefaultKeys.MapFilterInformation: true,
            UserDefaultKeys.MapFilterSafety: true,
            UserDefaultKeys.MapFilterObjects: true,
            UserDefaultKeys.MapFilterIntersections: false,
            UserDefaultKeys.MapFilterFootprints: true,
            UserDefaultKeys.IsUsingHeading: true,
            UserDefaultKeys.cacheDuration: Double(60 * 60), // In debug mode, default to 1 hour for the cache time interval
            UserDefaultKeys.EnvRenderingAlgorithm: -1,
            UserDefaultKeys.EnvRenderingDistance: 1.0,
            UserDefaultKeys.EnvRenderingReverbEnable: true,
            UserDefaultKeys.EnvRenderingReverbPreset: AVAudioUnitReverbPreset.mediumRoom.rawValue,
            UserDefaultKeys.EnvRenderingReverbBlend: 0.10,
            UserDefaultKeys.EnvRenderingReverbLevel: -20.0,
            UserDefaultKeys.EnvReverbFilterActive: false,
            UserDefaultKeys.EnvReverbFilterBandwidth: 0.5,
            UserDefaultKeys.isHeadphoneMotionEnabled: false,
            UserDefaultKeys.isHeadphoneMotionVerboseLoggingEnabled: false,
            UserDefaultKeys.isHeadphoneMotionDeviceHeadingEnabled: true,
            UserDefaultKeys.localPushNotification1TimeInternal: 172800, // 2 days
            UserDefaultKeys.localPushNotification2TimeInternal: 345600, // 4 days
            UserDefaultKeys.presentSurveyAlert: false
        ])
    }

    // MARK: Properties

    var showLogConsole: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.ShowLogConsole)
        }
        set(newShowLogConsole) {
            userDefaults.set(newShowLogConsole, forKey: UserDefaultKeys.ShowLogConsole)
        }
    }

    var loggers: [Logger] {
        get {
            guard let rawValues = userDefaults.array(forKey: UserDefaultKeys.Loggers) as? [Int] else {
                return Logger.local // Default loggers
            }
            return Logger.fromRawValues(rawValues: rawValues)
        }
        set(newLoggers) {
            userDefaults.set(Logger.toRawValues(loggers: newLoggers), forKey: UserDefaultKeys.Loggers)
        }
    }
    
    var servicesHostName: String? {
        get {
            return userDefaults.object(forKey: UserDefaultKeys.ServicesHostName) as? String
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: UserDefaultKeys.ServicesHostName)
        }
    }
    
    var assetsHostName: String? {
        get {
            return userDefaults.object(forKey: UserDefaultKeys.AssetsHostName) as? String
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: UserDefaultKeys.AssetsHostName)
        }
    }
    
    var gpxSimulationAudioEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.GPXSimulationAudioEnabled)
        }
        set(newFilter) {
            userDefaults.set(newFilter, forKey: UserDefaultKeys.GPXSimulationAudioEnabled)
        }
    }
    
    var gpxSimulationAudioPauseWithSimulation: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.GPXSimulationAudioPauseWithSimulation)
        }
        set(newFilter) {
            userDefaults.set(newFilter, forKey: UserDefaultKeys.GPXSimulationAudioPauseWithSimulation)
        }
    }
    
    var gpxSimulationAudioVolume: Float {
        get {
            return userDefaults.float(forKey: UserDefaultKeys.GPXSimulationAudioVolume)
        }
        set(newFilter) {
            userDefaults.set(newFilter, forKey: UserDefaultKeys.GPXSimulationAudioVolume)
        }
    }
    
    var cacheDuration: TimeInterval {
        get {
            return TimeInterval(userDefaults.double(forKey: UserDefaultKeys.cacheDuration))
        }
        set(newDuration) {
            userDefaults.set(newDuration, forKey: UserDefaultKeys.cacheDuration)
        }
    }
    
    var localPushNotification1TimeInternal: TimeInterval {
        get {
            return TimeInterval(userDefaults.double(forKey: UserDefaultKeys.localPushNotification1TimeInternal))
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: UserDefaultKeys.localPushNotification1TimeInternal)
        }
    }
    
    var localPushNotification2TimeInternal: TimeInterval {
        get {
            return TimeInterval(userDefaults.double(forKey: UserDefaultKeys.localPushNotification2TimeInternal))
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: UserDefaultKeys.localPushNotification2TimeInternal)
        }
    }
    
}

// MARK: 3D Rendering Parameters

extension DebugSettingsContext: EnvironmentSettingsProvider {
    
    var envRenderingAlgorithm: AVAudio3DMixingRenderingAlgorithm {
        get {
            let raw = userDefaults.integer(forKey: UserDefaultKeys.EnvRenderingAlgorithm)
            
            guard raw >= 0, let value = AVAudio3DMixingRenderingAlgorithm(rawValue: raw) else {
                return .HRTFHQ
            }
            
            return value
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: UserDefaultKeys.EnvRenderingAlgorithm)
        }
    }
    
    var envRenderingDistance: Double {
        get {
            return userDefaults.double(forKey: UserDefaultKeys.EnvRenderingDistance)
        }
        set(newDistance) {
            userDefaults.set(newDistance, forKey: UserDefaultKeys.EnvRenderingDistance)
        }
    }
    
    var envRenderingReverbEnable: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.EnvRenderingReverbEnable)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.EnvRenderingReverbEnable)
        }
    }
    
    var envRenderingReverbPreset: AVAudioUnitReverbPreset {
        get {
            return AVAudioUnitReverbPreset(rawValue: userDefaults.integer(forKey: UserDefaultKeys.EnvRenderingReverbPreset)) ?? .cathedral
        }
        set(newPreset) {
            userDefaults.setValue(newPreset.rawValue, forKey: UserDefaultKeys.EnvRenderingReverbPreset)
        }
    }
    
    var envRenderingReverbBlend: Float {
        get {
            return userDefaults.float(forKey: UserDefaultKeys.EnvRenderingReverbBlend)
        }
        set {
            userDefaults.setValue(max(0.0, min(1.0, newValue)), forKey: UserDefaultKeys.EnvRenderingReverbBlend)
        }
    }
    
    var envRenderingReverbLevel: Float {
        get {
            return userDefaults.float(forKey: UserDefaultKeys.EnvRenderingReverbLevel)
        }
        set {
            userDefaults.setValue(max(-40.0, min(40.0, newValue)), forKey: UserDefaultKeys.EnvRenderingReverbLevel)
        }
    }
    
    var envReverbFilterActive: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.EnvReverbFilterActive)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.EnvReverbFilterActive)
        }
    }
    
    var envReverbFilterBandwidth: Float {
        get {
            return userDefaults.float(forKey: UserDefaultKeys.EnvReverbFilterBandwidth)
        }
        set {
            userDefaults.setValue(max(0.05, min(5.0, newValue)), forKey: UserDefaultKeys.EnvReverbFilterBandwidth)
        }
    }
    
    var envReverbFilterBypass: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.EnvReverbFilterBypass)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.EnvReverbFilterBypass)
        }
    }
    
    var envReverbFilterType: AVAudioUnitEQFilterType {
        get {
            return AVAudioUnitEQFilterType(rawValue: userDefaults.integer(forKey: UserDefaultKeys.EnvReverbFilterType)) ?? .bandPass
        }
        set(newPreset) {
            userDefaults.setValue(newPreset.rawValue, forKey: UserDefaultKeys.EnvReverbFilterType)
        }
    }
    
    var envReverbFilterFrequency: Float {
        get {
            return userDefaults.float(forKey: UserDefaultKeys.EnvReverbFilterFrequency)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.EnvReverbFilterFrequency)
        }
    }
    
    var envReverbFilterGain: Float {
        get {
            return userDefaults.float(forKey: UserDefaultKeys.EnvReverbFilterGain)
        }
        set {
            userDefaults.setValue(max(-96.0, min(24.0, newValue)), forKey: UserDefaultKeys.EnvReverbFilterGain)
        }
    }
    
    var isHeadphoneMotionEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.isHeadphoneMotionEnabled)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.isHeadphoneMotionEnabled)
            
            // Post notification
            NotificationCenter.default.post(name: Notification.Name.isHeadphoneMotionEnabledDidChange, object: self)
        }
    }
    
    var isHeadphoneMotionVerboseLoggingEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.isHeadphoneMotionVerboseLoggingEnabled)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.isHeadphoneMotionVerboseLoggingEnabled)
        }
    }
    
    var isHeadphoneMotionDeviceHeadingEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.isHeadphoneMotionDeviceHeadingEnabled)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.isHeadphoneMotionDeviceHeadingEnabled)
        }
    }
    
    var isHeadphoneMotionCourseEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.isHeadphoneMotionCourseEnabled)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.isHeadphoneMotionCourseEnabled)
        }
    }
    
    var doubleLocalizedStringsEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.doubleLocalizedStrings)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.doubleLocalizedStrings)
        }
    }
    
    var boundedPseudolanguageEnabled: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.boundedPseudolanguage)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.boundedPseudolanguage)
        }
    }
    
    var presentSurveyAlert: Bool {
        get {
            return userDefaults.bool(forKey: UserDefaultKeys.presentSurveyAlert)
        }
        set {
            userDefaults.setValue(newValue, forKey: UserDefaultKeys.presentSurveyAlert)
        }
    }
}
