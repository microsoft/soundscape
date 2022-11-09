//
//  NavigationBarStyle.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI

enum NavigationBarStyle {
    case transparent(foregroundColor: Color)
    case darkBlue
}

extension NavigationBarStyle {
    
    var foregroundColor: Color {
        switch self {
        case .transparent(let foregroundColor): return foregroundColor
        case .darkBlue: return .white
        }
    }
    
    var foregroundUIColor: UIColor {
        switch self {
        case .transparent(let foregroundColor):
            guard let cgForegroundColor = foregroundColor.cgColor else {
                // Default color
                return .white
            }
            
            return UIColor(cgColor: cgForegroundColor)
        case .darkBlue: return .white
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .transparent: return Color.clear
        case .darkBlue: return Color.Theme.darkBlue
        }
    }
    
    var backgroundUIColor: UIColor {
        switch self {
        case .transparent: return UIColor.clear
        case .darkBlue: return UIColor.Theme.darkBlue
        }
    }
    
}

struct NavigationBarStyleModifier: ViewModifier {
    
    init(style: NavigationBarStyle) {
        // Appearance for given style
        let appearance = UINavigationBarAppearance(for: style)
        // Set appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set `tintColor`
        UINavigationBar.appearance().tintColor = style.foregroundUIColor
    }
    
    func body(content: Content) -> some View {
        return content
            .navigationBarTitleDisplayMode(.inline)
    }
    
}

extension View {
    
    func navigationBarStyle(style: NavigationBarStyle) -> some View {
        self.modifier(NavigationBarStyleModifier(style: style))
    }
    
}
