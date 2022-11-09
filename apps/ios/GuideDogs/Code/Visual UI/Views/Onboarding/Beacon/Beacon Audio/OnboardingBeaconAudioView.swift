//
//  OnboardingBeaconAudioView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingBeaconAudioView: View {
    
    // MARK: Properties
    
    @Binding var isPresented: Bool
    
    // MARK: `body`
    
    var body: some View {
        OnboardingContainer {
            GDLocalizedTextView("first_launch.beacon.audio.title")
                .onboardingHeaderTextStyle()
            
            GDLocalizedTextView("first_launch.beacon.audio.message")
                .onboardingTextStyle()
            
            InteractiveBeaconView()
                .frame(width: 350.0, height: 350.0)
                .accessibilityHidden(true)
            
            Button {
                isPresented = false
            } label: {
                GDLocalizedTextView("general.alert.done")
                    .onboardingButtonTextStyle()
            }
            .padding(.horizontal, 24.0)
        }
        .onAppear {
            GDATelemetry.trackScreenView("onboarding.beacon_audio")
        }
    }
    
}

struct OnboardingBeaconAudioView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingBeaconAudioView(isPresented: .constant(true))
        
        // Try a large font
        OnboardingBeaconAudioView(isPresented: .constant(true))
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
}
