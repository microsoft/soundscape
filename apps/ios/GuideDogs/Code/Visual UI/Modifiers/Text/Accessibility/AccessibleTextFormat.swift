//
//  AccessibleTextFormat.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct AccessibleTextFormat: ViewModifier {
    
    // Add accessibility-related modifiers to the SwiftUI
    // `Text` view
    func body(content: Content) -> some View {
        content
            .lineLimit(nil)
    }
    
}
