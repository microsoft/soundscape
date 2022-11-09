//
//  Palette.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

struct Palette {
    let color: Color
    let dark: Color
    let light: Color
    let neutralContrast: Color
}

extension Palette {
    
    enum Theme {
        
        static let yellow = Palette(color: Color.Theme.yellow, dark: Color.Theme.darkYellow, light: Color.Theme.lightYellow, neutralContrast: Color.black)
        
        static let teal = Palette(color: Color.Theme.teal, dark: Color.Theme.darkTeal, light: Color.Theme.lightTeal, neutralContrast: Color.white)
        
        static let blue = Palette(color: Color.Theme.blue, dark: Color.Theme.darkBlue, light: Color.Theme.lightBlue, neutralContrast: Color.white)
        
    }
    
}
