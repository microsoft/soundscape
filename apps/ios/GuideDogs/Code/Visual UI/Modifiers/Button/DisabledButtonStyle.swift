//
//  DisabledButtonStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct DisabledButtonStyle: ViewModifier {
    
    let isDisabled: Bool
    
    func body(content: Content) -> some View {
        return content
            .opacity(isDisabled ? 0.75 : 1.0)
            .disabled(isDisabled)
    }
    
}

extension View {
    
    func disabledButtonStyle(_ isDisabled: Bool) -> some View {
        self.modifier(DisabledButtonStyle(isDisabled: isDisabled))
    }
    
}
