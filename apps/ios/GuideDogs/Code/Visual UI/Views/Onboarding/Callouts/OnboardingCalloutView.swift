//
//  OnboardingCalloutView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingCalloutView: View {
    
    // MARK: Properties
    
    @State private var didComplete = false
    
    @ViewBuilder
    private var destination: some View {
        OnboardingAuthorizationView()
    }
    
    // MARK: `body`
    
    var body: some View {
        OnboardingContainer(coverImage: Image("Welcome-callouts")) {
            GDLocalizedTextView("first_launch.callouts.title")
                .onboardingHeaderTextStyle()
            
            GDLocalizedTextView("first_launch.callouts.message")
                .onboardingTextStyle()
            
            OnboardingCalloutButton(audioDidComplete: $didComplete)
                .padding(.horizontal, 8.0)
                .foregroundColor(.primaryForeground)
            
            OnboardingNavigationLink(destination: destination)
                .if(!didComplete, transform: { $0.hidden() })
        }
        .onAppear {
            GDATelemetry.trackScreenView("onboarding.callout")
        }
    }
    
}

struct OnboardingCalloutView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingCalloutView()
    }
    
}
