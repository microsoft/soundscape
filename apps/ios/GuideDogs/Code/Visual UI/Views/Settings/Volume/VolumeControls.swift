//
//  VolumeControls.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

struct VolumeControls: View {
    let beaconDemo = BeaconDemoHelper()
    
    @State private var ttsTimer: AnyCancellable?
    @State private var otherTimer: AnyCancellable?
    
    var body: some View {
        ZStack {
            Color.quaternaryBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    TableHeaderCell(text: GDLocalizedString("beacon.generic_name"))
                        .accessibility(hidden: true)
                    VolumeControlSlider(current: SettingsContext.shared.beaconVolume) { newValue in
                        SettingsContext.shared.beaconVolume = newValue
                        beaconDemo.play()
                    }
                    .accessibility(label: GDLocalizedTextView("beacon.generic_name"))
                    
                    TableHeaderCell(text: GDLocalizedString("settings.general.voice"))
                        .accessibility(hidden: true)
                    VolumeControlSlider(current: SettingsContext.shared.ttsVolume) { newValue in
                        SettingsContext.shared.ttsVolume = newValue
                        demoTTS()
                    }
                    .accessibility(label: GDLocalizedTextView("settings.general.voice"))
                    
                    TableHeaderCell(text: GDLocalizedString("settings.volume.other"))
                        .accessibility(hidden: true)
                    VolumeControlSlider(current: SettingsContext.shared.otherVolume) { newValue in
                        SettingsContext.shared.otherVolume = newValue
                        demoOther()
                    }
                    .accessibility(label: GDLocalizedTextView("settings.volume.other"))
                }
            }
        }
        .navigationTitle(GDLocalizedTextView("general.volume"))
        .onAppear {
            beaconDemo.prepare()
        }
        .onDisappear {
            ttsTimer?.cancel()
            ttsTimer = nil
            
            otherTimer?.cancel()
            otherTimer = nil
            
            beaconDemo.restoreState()
            
            let properties: [String: String] = [
                "beacon": "\(SettingsContext.shared.beaconVolume)",
                "tts": "\(SettingsContext.shared.ttsVolume)",
                "other": "\(SettingsContext.shared.otherVolume)"
            ]
            
            GDATelemetry.track("volume_settings.changed", with: properties)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            beaconDemo.prepare()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            beaconDemo.restoreState()
        }
    }
    
    private func demoTTS() {
        // When VoiceOver is running, we will wait until the current announcement has finished
        if !UIAccessibility.isVoiceOverRunning {
            AppContext.shared.eventProcessor.hush(playSound: false)
            AppContext.shared.audioEngine.stopDiscrete()
            AppContext.process(GenericAnnouncementEvent(GDLocalizedString("voice.voice_rate_test")))
        } else {
            ttsTimer?.cancel()
            ttsTimer = Timer.publish(every: 1.5, on: RunLoop.main, in: .common)
                .autoconnect()
                .first()
                .sink { _ in
                    AppContext.shared.eventProcessor.hush(playSound: false)
                    AppContext.shared.audioEngine.stopDiscrete()
                    AppContext.process(GenericAnnouncementEvent(GDLocalizedString("voice.voice_rate_test")))
                    ttsTimer = nil
                }
        }
    }
    
    private func demoOther() {
        // When VoiceOver is running, we will wait until the current announcement has finished
        if !UIAccessibility.isVoiceOverRunning {
            AppContext.shared.eventProcessor.hush(playSound: false)
            AppContext.shared.audioEngine.stopDiscrete()
            AppContext.process(GlyphEvent(.connectionSuccess))
        } else {
            otherTimer?.cancel()
            otherTimer = Timer.publish(every: 1.5, on: RunLoop.main, in: .common)
                .autoconnect()
                .first()
                .sink { _ in
                    AppContext.shared.eventProcessor.hush(playSound: false)
                    AppContext.shared.audioEngine.stopDiscrete()
                    AppContext.process(GlyphEvent(.connectionSuccess))
                    otherTimer = nil
                }
        }
    }
}

struct VolumeControls_Previews: PreviewProvider {
    static var previews: some View {
        VolumeControls()
    }
}
