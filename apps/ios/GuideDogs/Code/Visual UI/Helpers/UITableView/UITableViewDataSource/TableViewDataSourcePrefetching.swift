//
//  TableViewDataSourcePrefetching.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class TableViewDataSourcePrefetching<Model, CellConfigurator: TableViewCellConfigurator>: TableViewDataSource<Model, CellConfigurator>, UITableViewDataSourcePrefetching where CellConfigurator.Model == Model {
    
    // MARK: Properties
    
    private let dispatchGroup = DispatchGroup()
    
    private let queue = DispatchQueue(label: "com.company.appname.prefetchtable")
    
    // MARK: `TableViewDataSource`
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let fetchableModel: Fetchable = self.model(for: indexPath), fetchableModel.shouldFetch() {
            fetchableModel.fetch()
        }
        
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    // MARK: `TableViewDataSourcePrefetching`
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let model: Model = self.model(for: indexPath) else {
                continue
            }
            
            if let fetchableModel = model as? Fetchable, fetchableModel.shouldFetch() {
                dispatchGroup.enter()
                
                fetchableModel.fetchAsync(on: queue) { [weak self] in
                    self?.dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak tableView] in
            tableView?.reloadRows(at: indexPaths, with: .none)
        }
    }
    
}
