//
//  OnboardingCalloutButton.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingCalloutButton: View {
    
    // MARK: Properties
    
    @ScaledMetric(relativeTo: .body) private var animationSize: CGFloat = 18.0
    @Binding var audioDidComplete: Bool
    @State private var audioButtonOpacity = 1.0
    @State private var audioButtonIsAnimating = false
    
    // MARK: Initialization
    
    init(audioDidComplete: Binding<Bool>) {
        _audioDidComplete = audioDidComplete
    }
    
    // MARK: `body`
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            GDLocalizedTextView("first_launch.callouts.listen")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            Button {
                toggleAudio()
            } label: {
                HStack(spacing: 8.0) {
                    if audioButtonIsAnimating {
                        IsPlayingAnimation()
                            .frame(width: animationSize, height: animationSize, alignment: .center)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "play.circle")
                            .resizable()
                            .frame(width: animationSize, height: animationSize, alignment: .center)
                            .accessibilityHidden(true)
                    }
                    
                    GDLocalizedTextView("first_launch.callouts.listen.accessibility_label")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.body.bold())
                        .multilineTextAlignment(.leading)
                }
                .roundedBackground(Color.black.opacity(0.2))
                .accessibilityElement(children: .combine)
                .accessibilityHint(GDLocalizedTextView("first_launch.callouts.listen.accessibility_hint"))
            }
        }
        .onDisappear {
            AppContext.shared.eventProcessor.hush(playSound: true)
        }
    }
    
    // MARK: Audio
    
    private func toggleAudio() {
        // If the button is animating, audio is already
        // playing
        if audioButtonIsAnimating {
            GDATelemetry.track("onboarding.callout.hushed")
            
             AppContext.shared.eventProcessor.hush(playSound: true)
            
            stopAnimation(audioDidComplete: false)
        } else {
            GDATelemetry.track("onboarding.callout.started")
            
            startAnimation()
            
            AppContext.process(OnboardingExampleCalloutEvent { _ in
                GDATelemetry.track("onboarding.callout.completed")
                
                stopAnimation()
            })
        }
    }
    
    private func startAnimation() {
        if UIAccessibility.isVoiceOverRunning {
            audioButtonIsAnimating = true
        } else {
            withAnimation {
                audioButtonIsAnimating = true
            }
        }
    }
    
    private func stopAnimation(audioDidComplete: Bool = true) {
        if UIAccessibility.isVoiceOverRunning {
            audioButtonIsAnimating = false
            
            // If audio previously completed, ignore the new value for
            // `audioDidComplete`
            self.audioDidComplete = self.audioDidComplete || audioDidComplete
        } else {
            let duration = 0.5
            
            // Start animation sequence
            withAnimation(.easeIn(duration: duration)) {
                audioButtonIsAnimating = false
            }
            
            withAnimation(.easeIn(duration: duration).delay(duration)) {
                // If audio previously completed, ignore the new value for
                // `audioDidComplete`
                self.audioDidComplete = self.audioDidComplete || audioDidComplete
            }
        }
    }
    
}

struct OnboardingCalloutButton_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingContainer {
            OnboardingCalloutButton(audioDidComplete: .constant(false))
                .foregroundColor(.primaryForeground)
        }
        
        OnboardingContainer {
            // Try a different foreground color
            // Try using a larger font
            OnboardingCalloutButton(audioDidComplete: .constant(false))
                .foregroundColor(.greenHighlight)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
}
