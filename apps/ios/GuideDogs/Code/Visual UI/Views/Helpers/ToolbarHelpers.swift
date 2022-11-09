//
//  ToolbarHelpers.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

extension View {
    /// Embeds the content in a view which removes some
    /// default styling in toolbars, so accessibility works.
    ///
    /// See: https://stackoverflow.com/questions/65778208/accessibility-of-image-in-button-in-toolbaritem
    ///
    /// - Returns: Embedded content.
    @ViewBuilder func embedToolbarContent() -> some View {
        if #available(iOS 15, *) {
            self
        } else {
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                
                self
            }
        }
    }
}
