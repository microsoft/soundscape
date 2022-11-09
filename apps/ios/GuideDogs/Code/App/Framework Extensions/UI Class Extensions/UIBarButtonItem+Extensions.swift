//
//  UIBarButtonItem+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UIBarButtonItem {
    
    static var defaultBackBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(title: GDLocalizedString("ui.back_button.title"), style: .plain, target: nil, action: nil)
    }
    
}
