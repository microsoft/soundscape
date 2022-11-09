//
//  TableViewDataSourceProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol TableViewDataSourceProtocol: UITableViewDataSource {
    func header(in section: Int) -> String?
    func model<Model>(for indexPath: IndexPath) -> Model?
}
