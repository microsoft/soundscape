//
//  SectionedTableViewDataSource.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class SectionedTableViewDataSource: NSObject, TableViewDataSourceProtocol {

    // MARK: Properties
    
    private let dataSources: [UITableViewDataSource]
    
    // MARK: Initialization
    
    init(dataSources: [UITableViewDataSource]) {
        self.dataSources = dataSources
        
        super.init()
    }
    
    // MARK: `TableViewDataSourceProtocol`
    
    func header(in section: Int) -> String? {
        guard section < dataSources.count else {
            return nil
        }
        
        guard let tableViewdataSource = dataSources[section] as? TableViewDataSourceProtocol else {
            return nil
        }
        
        return tableViewdataSource.header(in: section)
    }
    
    func model<Model>(for indexPath: IndexPath) -> Model? {
        guard indexPath.section < dataSources.count else {
            return nil
        }
        
        guard let tableViewdataSource = dataSources[indexPath.section] as? TableViewDataSourceProtocol else {
            return nil
        }
        
        return tableViewdataSource.model(for: indexPath)
    }
    
    // MARK: `UITableViewDataSource`
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSources.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < dataSources.count else {
            return 0
        }

        return dataSources[section].tableView(tableView, numberOfRowsInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < dataSources.count else {
            return nil
        }

        return dataSources[section].tableView?(tableView, titleForHeaderInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < dataSources.count else {
            return tableView.dequeueReusableCell(forIndexPath: indexPath)
        }
        
        return dataSources[indexPath.section].tableView(tableView, cellForRowAt: IndexPath(row: indexPath.row, section: 0))
    }
    
}
