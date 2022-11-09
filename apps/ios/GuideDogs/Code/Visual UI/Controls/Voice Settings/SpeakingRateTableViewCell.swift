//
//  SpeakingRateTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class SpeakingRateTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var speakingRateSlider: UISlider!
    fileprivate var previousWorkItem: DispatchWorkItem?
    
    func initialize() {
        // We only want to receive the valueChanged event when the user stops moving the slider.
        speakingRateSlider.isContinuous = false
        
        // Load the speaking rate setting.
        speakingRateSlider.value = SettingsContext.shared.speakingRate
    }
    
    // MARK: Speaking Rate
    
    @IBAction func onSpeakingRateSliderValueChanged() {
        SettingsContext.shared.speakingRate = speakingRateSlider.value
        
        announcementTest()
        
        GDATelemetry.track("settings.voice.rate", with: ["value": String(speakingRateSlider.value), "voice": SettingsContext.shared.voiceId ?? "not_set"])
    }
    
    fileprivate func announcementTest() {
        let test = {
            AppContext.shared.eventProcessor.hush(playSound: false)
            AppContext.shared.audioEngine.stopDiscrete()
            AppContext.process(GenericAnnouncementEvent(GDLocalizedString("voice.voice_rate_test")))
        }
        
        // When VoiceOver is running, we will wait until the current announcement has finished
        if !UIAccessibility.isVoiceOverRunning {
            test()
        } else {
            previousWorkItem?.cancel()
            
            previousWorkItem = DispatchWorkItem {
                test()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: previousWorkItem!)
        }
    }
    
}
