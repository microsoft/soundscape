//
//  TitleTextFieldItem.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum TitleTextFieldItem {
    case name
    case description
    
    var title: String {
        switch self {
        case .name: return GDLocalizedString("markers.sort_button.sort_by_name")
        case .description: return GDLocalizedString("route_detail.edit.description")
        }
    }
    
    var defaultValue: String? {
        switch self {
        case .name: return nil
        case .description: return GDLocalizedString("route_detail.edit.description.default")
        }
    }
}
