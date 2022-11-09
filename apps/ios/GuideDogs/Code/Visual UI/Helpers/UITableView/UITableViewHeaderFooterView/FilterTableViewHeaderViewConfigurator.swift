//
//  FilterTableViewHeaderViewConfigurator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class FilterTableViewHeaderViewConfigurator: TableViewHeaderViewConfigurator {
    
    typealias TableViewHeader = FilterTableViewHeaderView
    
    // MARK: Properties
    
    weak var delegate: FilterTableViewHeaderViewDelegate?
    var action: FilterTableViewHeaderView.Action?
    
    // MARK: `TableViewHeaderFooterViewConfigurator`
    
    func configure(_ view: FilterTableViewHeaderView, forDisplaying title: String) {
        // Save delegate
        view.delegate = delegate
        
        // Configure title label
        view.titleLabel.text = title
        
        // Configure action button
        if let action = action, let delegate = delegate, delegate.isEnabled {
            view.actionButton.setTitle(action.localizedTitle, for: .normal)
            view.actionButton.isHidden = false
            view.accessibilityHint = action.localizedAccessibilityHint
        } else {
            view.actionButton.isHidden = true
        }
    }
}
