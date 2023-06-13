//
//  LocationNameTextFormat.swift
//  Openscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct LocationNameTextFormat: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.primaryForeground)
            .font(.body)
            .accessibleTextFormat()
    }
    
}
