//
//  OnboardingHeadphoneView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingHeadphoneView: View {
    
    // MARK: Properties
    
    @State private var titleScale = 1.25
    @State private var titleIsHidden = true
    @State private var contentIsHidden = true
    
    private var coverImage: Image? {
        return contentIsHidden ? nil : Image("Welcome-buttons")
    }
    
    @ViewBuilder
    private var destination: some View {
        OnboardingCalloutView()
    }
    
    // MARK: `body`
    
    var body: some View {
        OnboardingContainer(coverImage: coverImage) {
            if titleIsHidden == false {
                GDLocalizedTextView("first_launch.headphones.title")
                    .onboardingHeaderTextStyle()
                    .scaleEffect(titleScale)
            }
            
            if contentIsHidden == false {
                VStack(spacing: 8.0) {
                    GDLocalizedTextView("first_launch.headphones.message.1")
                        .onboardingTextStyle()
                    
                    GDLocalizedTextView("first_launch.headphones.message.2")
                        .onboardingTextStyle()
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                OnboardingNavigationLink(destination: destination)
            } else {
                Spacer()
            }
        }
        .onAppear {
            GDATelemetry.trackScreenView("onboarding.headphone")
            
            animateView()
        }
    }
    
    private func animateView() {
        if UIAccessibility.isVoiceOverRunning || UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            titleIsHidden = false
            titleScale = 1.0
            contentIsHidden = false
        } else {
            let duration = 0.5
            let delay = 0.25
            
            // Start animation sequence
            withAnimation(.easeIn(duration: duration).delay(delay)) {
                titleIsHidden = false
            }
            
            withAnimation(.easeIn(duration: duration).delay(delay + duration)) {
                titleScale = 1.0
                contentIsHidden = false
            }
        }
    }
    
}
struct OnboardingHeadphoneView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingHeadphoneView()
    }
    
}
