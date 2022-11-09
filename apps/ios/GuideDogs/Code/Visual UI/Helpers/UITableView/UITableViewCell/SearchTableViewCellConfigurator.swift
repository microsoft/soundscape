//
//  SearchTableViewCellConfigurator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class SearchTableViewCellConfigurator: TableViewCellConfigurator {
    
    typealias TableViewCell = SearchTableViewCell
    typealias Model = String
    
    // MARK: `TableViewCellConfigurator`
    
    var accessibilityHint: String?
    
    func configure(_ cell: TableViewCell, forDisplaying model: Model) {
        cell.textLabel?.text = GDLocalizedString("search.search_for", model)
    }
    
}
