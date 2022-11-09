//
//  StaticAudioEngineAsset.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum StaticAudioEngineAsset: String, AudioEngineAsset {
    
    // MARK: Earcons/Glyphs
    
    case enterMode          = "mode_enter"
    case exitMode           = "mode_exit"
    case hush               = "hush"
    case infoAlert          = "information_alert"
    case invalidFunction    = "invalid_function"
    case startJourney       = "callouts_on"
    case stopJourney        = "callouts_off"
    case locationSense      = "sense_location"
    case mobilitySense      = "sense_mobility"
    case poiSense           = "sense_poi"
    case safetySense        = "sense_safety"
    case appLaunch          = "app_launch"
    case flagFound          = "flag_found"
    case huntComplete       = "hunt_complete"
    case offline            = "offline"
    case online             = "online"
    case calibrationSuccess = "calibration_success"
    case lowConfidence      = "low_confidence" // This isn't currently used
    case connectionSuccess  = "connection_success"
    case beaconFound        = "SS_beaconFound2_48k"
    case tourPoiSense       = "sense_tourpoi"
    
    static let startListening = StaticAudioEngineAsset.enterMode
    static let stopListening = StaticAudioEngineAsset.exitMode
    static let tellMeMore = StaticAudioEngineAsset.appLaunch
    
    // MARK: Continuous Audio
    
    case calibrationInProgress = "calibration_in_progress"
    
    // MARK: Location Preview
    
    case previewStart = "SS_logo4_48k"
    case previewEnd = "Aug12_Experience_end_4c"
    case streetFound = "SS_streetFound_48k"
    case travelStart = "Travel_start_v2_spatial_48k"
    case travelInter = "Travel_inter_v2_spatial_48k"
    case travelEnd = "Travel_end_v2_spatial_48k"
    case travelReverse = "Travel_reverse_v2_spatial_48k"
    case roadFinderError = "street_non_1c"
}
