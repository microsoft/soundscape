//
//  RoundedBackground.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct RoundedBackground<Background: View>: ViewModifier {
    
    let background: Background
    let padding: Double
    let cornerRadius: Double
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(padding) // Padding around background
            .background(background)
            .cornerRadius(cornerRadius)
            .accessibleTextFormat() // Ensure content is accessible
            .accessibilityElement(children: .combine)
    }
    
}

extension View {
    
    func roundedBackground<Background: View>(padding: Double = 10.0, cornerRadius: Double = 5.0, _ background: Background) -> some View {
        modifier(RoundedBackground(background: background, padding: padding, cornerRadius: cornerRadius))
    }
    
}
