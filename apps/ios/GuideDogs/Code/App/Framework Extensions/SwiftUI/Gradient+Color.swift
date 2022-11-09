//
//  Gradient+Color.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

extension Gradient {
    
    static var purple: Gradient {
        return Gradient(colors: [
            Color(.sRGB, red: 0.182, green: 0.123, blue: 0.796, opacity: 1.0),
            Color(.sRGB, red: 0.443, green: 0.086, blue: 0.792, opacity: 1.0)
        ])
    }
    
    static var blue: Gradient {
        return Gradient(colors: [
            Color(.sRGB, red: 0.03, green: 0.179, blue: 0.562, opacity: 1.0),
            Color(.sRGB, red: 0.246, green: 0.446, blue: 0.746, opacity: 1.0)
        ])
    }
    
    static var darkBlue: Gradient {
        return Gradient(colors: [
            Color(.sRGB, red: 0.026, green: 0.199, blue: 0.371, opacity: 1),
            Color(.sRGB, red: 0.101, green: 0.406, blue: 0.608, opacity: 1)
        ])
    }
    
}
