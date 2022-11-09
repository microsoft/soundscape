//
//  LocalizedLabel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct LocalizedLabel {
    let text: String
    // `nil` if the accessibility label is the same as the label
    // text
    let accessibilityText: String?
}

extension LocalizedLabel {
    
    func appending(_ aLocalizedLabel: LocalizedLabel, localizedSeparator: String = " ", localizedAccessibilitySeparator: String? = ", ") -> LocalizedLabel {
        let newText = text + localizedSeparator + aLocalizedLabel.text
        let newAccessibilityText = (accessibilityText ?? text) + (localizedAccessibilitySeparator ?? localizedSeparator) + (aLocalizedLabel.accessibilityText ?? aLocalizedLabel.text)
            
        return LocalizedLabel(text: newText, accessibilityText: newAccessibilityText)
    }
    
}
