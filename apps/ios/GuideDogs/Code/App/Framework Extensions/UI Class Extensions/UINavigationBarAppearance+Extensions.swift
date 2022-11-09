//
//  UINavigationBarAppearance+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UINavigationBarAppearance {
    
    convenience init(for navigationBarStyle: NavigationBarStyle) {
        self.init()
        
        switch navigationBarStyle {
        case .transparent: configureWithTransparentBackground()
        case .darkBlue: configureWithOpaqueBackground()
        }
        
        // Background and foreground colors
        backgroundColor = navigationBarStyle.backgroundUIColor
        titleTextAttributes = [.foregroundColor: navigationBarStyle.foregroundUIColor]
        
        // Navigation bar button foreground color
        let bAppearance = UIBarButtonItemAppearance()
        bAppearance.normal.titleTextAttributes = [.foregroundColor: navigationBarStyle.foregroundUIColor]
        self.buttonAppearance = bAppearance
    }
    
}
