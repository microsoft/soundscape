//
//  TableViewDataSource.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// This class is designed to reduce repeating code when creating a table view.
/// Given a header, array of `Model` objects and a corresponding `CellConfigurator`, this class implements
/// the standard `UITableViewDataSource` methods, including dequeing and configuring the view for each
/// cell in the table.
class TableViewDataSource<Model, CellConfigurator: TableViewCellConfigurator>: NSObject, TableViewDataSourceProtocol where CellConfigurator.Model == Model {
    
    // MARK: Properties
    
    private let header: String?
    private let models: [Model]
    private let cellConfigurator: CellConfigurator
    private var didRegisterCell = false
    
    // MARK: Initialization
    
    init(header: String?, models: [Model], cellConfigurator: CellConfigurator) {
        self.header = header
        self.models = models
        self.cellConfigurator = cellConfigurator
        
        super.init()
    }
    
    // MARK: `TableViewDataSourceProtocol`
    
    func header(in section: Int) -> String? {
        return header
    }
    
    func model<Model>(for indexPath: IndexPath) -> Model? {
        guard indexPath.row < models.count else {
            return nil
        }
        
        return models[indexPath.row] as? Model
    }
    
    // MARK: `TableViewDataSource`
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")

        guard indexPath.row < models.count else {
            return defaultCell
        }
        
        if didRegisterCell == false {
            // Register cell
            tableView.registerCell(CellConfigurator.TableViewCell.self)
            didRegisterCell = true
        }
        
        let cell: CellConfigurator.TableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cellConfigurator.configure(cell, forDisplaying: models[indexPath.row])
        
        return cell
    }
    
}
