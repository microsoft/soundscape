//
//  ColorPaletteKey.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

private struct ColorPaletteKey: EnvironmentKey {
    static let defaultValue: Palette = Palette.Theme.blue
}

extension EnvironmentValues {
    var colorPalette: Palette {
        get { self[ColorPaletteKey.self] }
        set { self[ColorPaletteKey.self] = newValue }
    }
}

extension View {
    func colorPalette(_ value: Palette) -> some View {
        environment(\.colorPalette, value)
    }
}
