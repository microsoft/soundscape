//
//  POITableViewHeaderViewConfigurator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class POITableViewHeaderViewConfigurator: TableViewHeaderViewConfigurator {
    
    typealias TableViewHeader = POITableViewHeaderView
    
    // MARK: `TableViewHeaderFooterViewConfigurator`
    
    func configure(_ view: POITableViewHeaderView, forDisplaying title: String) {
        view.titleLabel.text = title
        view.titleLabel.accessibilityLabel = title
        view.accessibilityTraits = UIAccessibilityTraits.header
    }
    
}
