//
//  ConditionalAccessibilityAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct ConditionalAccessibilityAction: ViewModifier {
    let isActive: Bool
    let name: Text
    let handler: () -> Void

    func body(content: Content) -> some View {
        if isActive {
            content.accessibilityAction(named: name, handler)
        } else {
            content
        }
    }
}

extension View {
    func conditionalAccessibilityAction(_ isActive: Bool, named name: Text, handler: @escaping () -> Void) -> some View {
        modifier(ConditionalAccessibilityAction(isActive: isActive, name: name, handler: handler))
    }
}
