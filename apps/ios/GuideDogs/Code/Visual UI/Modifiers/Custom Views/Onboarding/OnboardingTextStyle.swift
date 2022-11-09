//
//  OnboardingTextStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct OnboardingTextStyle: ViewModifier {
    
    let font: Font
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(Color.primaryForeground)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12.0)
            .accessibleTextFormat()
    }
    
}

extension Text {
    
    func onboardingTextStyle(font: Font = .body) -> some View {
        modifier(OnboardingTextStyle(font: font))
    }
    
    func onboardingHeaderTextStyle(font: Font = .largeTitle.bold()) -> some View {
        modifier(OnboardingTextStyle(font: font))
            .accessibilityAddTraits(.isHeader)
    }

}
