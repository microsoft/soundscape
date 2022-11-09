//
//  RoundedBorder.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct RoundedBorder: ViewModifier {
    
    let lineColor: Color
    let lineWidth: Double
    let cornerRadius: Double
    
    func body(content: Content) -> some View {
        return content
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineColor, lineWidth: lineWidth)
            )
    }
    
}

extension View {
    
    func roundedBorder(lineColor: Color, lineWidth: Double = 1.0, cornerRadius: Double = 5.0) -> some View {
        self.modifier(RoundedBorder(lineColor: lineColor, lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
    
}
