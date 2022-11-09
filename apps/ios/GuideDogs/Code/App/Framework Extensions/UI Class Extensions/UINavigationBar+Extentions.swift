//
//  UINavigationBar+Extentions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

extension UINavigationBar {
    
    enum Style {
        // Navigation bar appearance used by most of the app's views
        case `default`
        // Transparent background with light (white) foreground
        case transparentLightTitle
    }
    
    func configureAppearance(for style: Style) {
        switch style {
        case .default: configureDefaultAppearance()
        case .transparentLightTitle: configureTransparentAppearance()
        }
    }
    
    private func configureDefaultAppearance() {
        let color = Colors.Foreground.primary ?? UIColor.white
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: color]
        
        let appearance = UINavigationBarAppearance()
        
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.Background.primary
        appearance.titleTextAttributes = [.foregroundColor: color]
        appearance.buttonAppearance = buttonAppearance
        
        apply(appearance)
        
        tintColor = color
    }
    
    private func configureTransparentAppearance() {
        let color = Colors.Foreground.primary ?? UIColor.white
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: color]
        
        let appearance = UINavigationBarAppearance()
        
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: color]
        appearance.buttonAppearance = buttonAppearance
        
        apply(appearance)
        
        tintColor = color
    }
    
    private func apply(_ appearance: UINavigationBarAppearance) {
        // Apply the given appearance
        standardAppearance = appearance
        scrollEdgeAppearance = appearance
        compactAppearance = appearance
        
        // Set the back button
        items?.forEach({ $0.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem })
    }
    
}
