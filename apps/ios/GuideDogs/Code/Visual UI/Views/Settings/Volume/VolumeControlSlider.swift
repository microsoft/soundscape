//
//  VolumeControlSlider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct VolumeControlSlider: View {
    @State private var largeStep: Bool = UIAccessibility.isVoiceOverRunning
    @State var volume: Float
    
    let onUpdate: (Float) -> Void
    
    init(current: Float, onUpdate: @escaping (Float) -> Void) {
        _volume = State(initialValue: current * 100.0)
        
        self.onUpdate = onUpdate
    }
    
    var step: Float {
        if largeStep {
            return 5.0
        } else {
            return 1.0
        }
    }
    
    var body: some View {
        Slider(value: $volume, in: 0 ... 100, step: step) { isEditing in
            if !isEditing {
                onUpdate(volume / 100.0)
            }
        }
        .accentColor(.secondaryForeground)
        .padding()
        .accessibilityLabel(GDLocalizedTextView("general.volume"))
        .accessibilityValue(Text(String(Int(volume))))
        .background(Color.primaryBackground)
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification), perform: { _ in
            largeStep = UIAccessibility.isVoiceOverRunning
        })
    }
}

struct BeaconVolumeSlider_Previews: PreviewProvider {
    static var previews: some View {
        VolumeControlSlider(current: 1.0) { _ in
            // ignore
        }
    }
}
