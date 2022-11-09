//
//  OnboardingPromptView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingPromptView: View {
    
    // MARK: Properties
    
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var titleScale = 1.5
    @State private var titleIsHidden = true
    @State private var contentIsHidden = true
    
    private var coverImage: Image? {
        return contentIsHidden ? nil : Image("permissions-location")
    }
    
    // MARK: `body`
    
    var body: some View {
        OnboardingContainer(coverImage: coverImage) {
            if titleIsHidden == false {
                Spacer()
                
                GDLocalizedTextView("first_launch.prompt.title")
                    .onboardingHeaderTextStyle()
            }
            
            if contentIsHidden == false {
                GDLocalizedTextView("first_launch.prompt.message")
                    .onboardingTextStyle()
                
                Spacer()
                
                Button {
                    // If onboarding has already been completed,
                    // then onboarding was started from app settings
                    GDATelemetry.track("onboarding.completed", with: [ "first_launch": "\(!FirstUseExperience.didComplete(.oobe))"])
                    
                    viewModel.dismiss()
                } label: {
                    GDLocalizedTextView("first_launch.prompt.button")
                        .onboardingButtonTextStyle()
                }
                .padding(.horizontal, 24.0)
            } else {
                Spacer()
            }
        }
        .onAppear {
            GDATelemetry.trackScreenView("onboarding.prompt")
            
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

struct FirstLaunchPromptView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingPromptView()
            .environmentObject(OnboardingViewModel())
    }
    
}
