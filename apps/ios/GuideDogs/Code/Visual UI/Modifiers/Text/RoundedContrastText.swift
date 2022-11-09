//
//  RoundedContrastText.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct RoundedContrastText: ViewModifier {
    
    let padding: Double
    
    func body(content: Content) -> some View {
        content
            .padding(padding) // Padding around background
            .background(Color.Theme.extraDarkGray.opacity(0.9))
            .cornerRadius(5.0)
            .accessibleTextFormat()
            .foregroundColor(.white)
    }
    
}

extension View {
    
    func roundedContrastText(padding: Double = 12.0) -> some View {
        modifier(RoundedContrastText(padding: padding))
    }
    
}
