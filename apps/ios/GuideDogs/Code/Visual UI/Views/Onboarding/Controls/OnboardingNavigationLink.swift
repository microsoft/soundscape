//
//  OnboardingNavigationLink.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct OnboardingNavigationLink<Destination: View>: View {
    
    // MARK: Properties
    
    private let text: String
    private let destination: Destination
    
    // MARK: Initialization
    
    init(text: String = GDLocalizedString("ui.continue"), destination: Destination) {
        self.text = text
        self.destination = destination
    }
    
    // MARK: `body`
    
    var body: some View {
        NavigationLink(destination: destination) {
            Text(text)
                .onboardingButtonTextStyle()
        }
        .padding(.horizontal, 24.0)
    }
    
}

struct OnboardingNavigationLink_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingContainer {
            // Try default text
            OnboardingNavigationLink(destination: EmptyView())
            
            // Try custom text
            OnboardingNavigationLink(text: "Press Me!", destination: EmptyView())
        }
    }
    
}
