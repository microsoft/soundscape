//
//  OnboardingContainer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingContainer<Content: View>: View {
    
    // MARK: Properties
    
    private let coverImage: Image?
    private let coverImageAccessibilityLabel: String?
    private let content: () -> Content
    
    // MARK: Initialization
    
    init(coverImage: Image? = nil, accessibilityLabel: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.coverImage = coverImage
        self.coverImageAccessibilityLabel = accessibilityLabel
        self.content = content
        
        // Disable bounce
        UIScrollView.appearance().bounces = false
    }
    
    // MARK: `body`
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32.0) {
                if let coverImage = coverImage {
                    if let accessibilityLabel = coverImageAccessibilityLabel {
                        coverImage
                            .resizable()
                            .scaledToFill()
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibility(label: Text(accessibilityLabel))
                    } else {
                        coverImage
                            .resizable()
                            .scaledToFill()
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibility(hidden: true)
                    }
                }
                
                content()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 48.0)
        }
        .linearGradientBackground(.darkBlue, ignoresSafeArea: true)
        .navigationBarHidden(true)
        .accessibilityIgnoresInvertColors(true)
    }
    
}

struct OnboardingContainer_Previews: PreviewProvider {
    
    static var previews: some View {
        // Try without a cover image
        OnboardingContainer {
            Text("Welcome!")
                .onboardingHeaderTextStyle()
        }
        
        // Try with a cover image
        OnboardingContainer(coverImage: Image("permissions-intro")) {
            Text("Welcome!")
                .onboardingHeaderTextStyle()
            
            Spacer()
            
            OnboardingNavigationLink(text: "Continue", destination: EmptyView())
        }
        
        // Try with long text that will require a scroll view
        OnboardingContainer(coverImage: Image("permissions-intro")) {
            Text("Welcome!")
                .onboardingHeaderTextStyle()
            
            Text("This is a very long paragraph to test how the container and scroll view manage large font sizes. A long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long paragraph.")
                .onboardingTextStyle()
            
            Spacer()
            
            OnboardingNavigationLink(text: "Continue", destination: EmptyView())

        }
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
}
