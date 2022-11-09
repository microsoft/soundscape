//
//  LeftAccessoryText.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct LeftAccessoryText: View {
    
    let text: String
    let leftAccessory: Image
    
    var body: some View {
        (Text(leftAccessory) + Text(" ") + Text(text))
            .accessibilityLabel(text) // Hide left accessory from accessibility view
    }
    
}

struct LeftAccessoryText_Previews: PreviewProvider {
    
    static var previews: some View {
        LeftAccessoryText(text: "A button", leftAccessory: Image(systemName: "camera.macro.circle.fill"))
    }
    
}
