//
//  TableViewCellConfigurator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// This protocol can be used along with a `TableViewDataSource` to control how
/// a cell's custom view should be configured in a table
protocol TableViewCellConfigurator: AnyObject {
    associatedtype TableViewCell: UITableViewCell, NibLoadableView
    associatedtype Model
    
    // MARK: `UITableViewCell`
    func configure(_ cell: TableViewCell, forDisplaying model: Model)
}
