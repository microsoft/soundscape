//
//  LocationAddressTextFormat.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct LocationAddressTextFormat: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.tertiaryForeground)
            .font(.footnote)
            .accessibleTextFormat()
    }
    
}
