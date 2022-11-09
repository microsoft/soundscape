//
//  LocationDistanceTextFormat.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct LocationDistanceTextFormat: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.yellowHighlight)
            .font(.footnote)
            .accessibleTextFormat()
    }
    
}
