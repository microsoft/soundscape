//
//  PlainListRowBackground.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct PlainListRowBackground: ViewModifier {
    
    let backgroundColor: Color
    let colorScheme: ColorScheme
    
    init(backgroundColor: Color, colorScheme: ColorScheme = .light) {
        self.backgroundColor = backgroundColor
        self.colorScheme = colorScheme
    }
    
    func body(content: Content) -> some View {
        content
            .listRowBackground(backgroundColor)
            // Disable insets on the list row
            .listRowInsets(EdgeInsets())
            // When using iOS list row modifiers (e.g., delete, move)
            // against a dark background, set the color scheme to `.dark`
            .colorScheme(colorScheme)
    }
    
}

extension View {
    
    func plainListRowBackground(_ backgroundColor: Color, colorScheme: ColorScheme = .light) -> some View {
        modifier(PlainListRowBackground(backgroundColor: backgroundColor, colorScheme: colorScheme))
    }
    
}
