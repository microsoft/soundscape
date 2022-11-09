//
//  StaticTableViewDataSource.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol StaticTableViewCell {
    var identifier: String { get }
}

class StaticTableViewDataSource: NSObject, TableViewDataSourceProtocol {
    
    // MARK: Properties
    
    private let header: String?
    let cells: [StaticTableViewCell]
    
    // MARK: Initialization
    
    init(header: String?, cells: [StaticTableViewCell]) {
        self.header = header
        self.cells = cells
        
        super.init()
    }
    
    // MARK: `TableViewDataSourceProtocol`
    
    func header(in section: Int) -> String? {
        return header
    }
    
    func model<Model>(for indexPath: IndexPath) -> Model? {
        return nil
    }
    
    // MARK: `UITableViewDataSource`
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return 0
        }
        
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 0 else {
            return nil
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
        
        guard indexPath.section == 0 else {
            return defaultCell
        }
        
        guard indexPath.row < cells.count else {
            return defaultCell
        }
        
        let identifier = cells[indexPath.row].identifier
        return tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }
    
}
