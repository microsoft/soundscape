//
//  OnboardingLanguageView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingLanguageView: View {
    
    // MARK: Properties
    
    @State private var selectedLocale: Locale = LocalizationContext.currentAppLocale
    
    @ViewBuilder
    private var destination: some View {
        OnboardingHeadphoneView()
    }
    
    // MARK: `body`
    
    var body: some View {
        OnboardingContainer {
            VStack(spacing: 12.0) {
                GDLocalizedTextView("first_launch.soundscape_language")
                    .onboardingHeaderTextStyle()
                
                GDLocalizedTextView("first_launch.beacon.message.3")
                    .onboardingTextStyle(font: .callout)
            }
            
            LanguagePickerView(selectedLocale: $selectedLocale)
            
            OnboardingNavigationLink(destination: destination)
        }
        .onAppear {
            GDATelemetry.trackScreenView("onboarding.language_picker")
        }
    }
    
}

struct OnboardingLanguageView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingLanguageView()
    }
    
}
