//
//  OnboardingBeaconView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingBeaconView: View {
    
    // MARK: Properties
    
    @State private var didComplete = false
    @State private var selectedBeacon: BeaconOption?
    @State private var isAudioViewPresented = false
    
    @ViewBuilder
    private var destination: some View {
        if FirstUseExperience.didComplete(.oobe) {
            // If onboarding has already been completed,
            // skip `OnboardingTermsView`
            OnboardingPromptView()
        } else {
            OnboardingTermsView()
        }
    }
    
    // MARK: `body`
    
    var body: some View {
        OnboardingContainer {
            GDLocalizedTextView("first_launch.beacon.title")
                .onboardingHeaderTextStyle()
            
            GDLocalizedTextView("first_launch.beacon.message.1")
                .onboardingTextStyle()
            
            VStack(spacing: 12.0) {
                GDLocalizedTextView("first_launch.beacon.message.2")
                    .onboardingTextStyle()
                
                GDLocalizedTextView("first_launch.beacon.message.3")
                    .onboardingTextStyle(font: .callout.bold())
            }
            .accessibilityElement(children: .combine)
            
            BeaconPickerView(selectedBeacon: $selectedBeacon)
                .onChange(of: selectedBeacon) { _ in
                    guard let selectedBeacon = selectedBeacon else {
                        return
                    }

                    SettingsContext.shared.selectedBeacon = selectedBeacon.id
                    isAudioViewPresented = true
                }
            
            Spacer()
            
            OnboardingNavigationLink(destination: destination)
                .if(!didComplete, transform: { $0.hidden() })
        }
        .sheet(isPresented: $isAudioViewPresented) {
            withAnimation(.easeInOut(duration: 1.0)) {
                guard didComplete == false else {
                    return
                }
                
                didComplete = selectedBeacon != nil
            }
        } content: {
            OnboardingBeaconAudioView(isPresented: $isAudioViewPresented)
        }
        .onAppear {
            GDATelemetry.trackScreenView("onboarding.beacon_picker")
            
            AppContext.shared.start(fromFirstLaunch: true)
        }
    }
    
}

struct OnboardingBeaconView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingBeaconView()
    }
    
}
