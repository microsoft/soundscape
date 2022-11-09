//
//  LinearGradientViewBackground.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct LinearGradientBackground: ViewModifier {
    
    let gradient: Gradient
    let ignoresSafeArea: Bool
    
    @ViewBuilder
    private var linearGradientView: some View {
        LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    func body(content: Content) -> some View {
        if ignoresSafeArea {
            ZStack {
                linearGradientView
                    .ignoresSafeArea()
                
                content
            }
        } else {
            content
                .background(
                    linearGradientView
                )
        }
    }
    
}

extension View {
    
    func linearGradientBackground(_ gradient: Gradient, ignoresSafeArea: Bool = false) -> some View {
        modifier(LinearGradientBackground(gradient: gradient, ignoresSafeArea: ignoresSafeArea))
    }
    
}
