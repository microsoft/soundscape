//
//  Labels & Text Views.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

extension LocalizedLabel {
    
    var accessibleTextView: some View {
        return accessibleTextView(leftAccessory: nil)
    }
    
    func accessibleTextView(leftAccessory: Image? = nil) -> some View {
        if let leftAccessory = leftAccessory {
            return (Text(leftAccessory) + Text("  ") + Text(text))
                .ifLet(accessibilityText, if: { $0.accessibilityLabel($1) }, else: { $0.accessibilityLabel(text) })
        } else {
            return Text(text)
                .ifLet(accessibilityText, if: { $0.accessibilityLabel($1) }, else: { $0.accessibilityLabel(text) })
        }
    }
    
}
