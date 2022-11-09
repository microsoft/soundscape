//
//  TableViewDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol TableViewSelectDelegate: AnyObject {
    func didSelect(rowAtIndexPath indexPath: IndexPath)
}

class TableViewDelegate: NSObject, UITableViewDelegate {
    
    // MARK: Properties
    
    weak var delegate: TableViewSelectDelegate?
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        delegate?.didSelect(rowAtIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let dataSource = tableView.dataSource as? TableViewDataSourceProtocol, dataSource.header(in: section) == nil {
            // If no header is provided, hide `headerView`
            return 0.0
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
}

extension TableViewDelegate {
    
    static func make(selectDelegate: TableViewSelectDelegate?) -> TableViewDelegate {
        let tableViewDelegate = TableViewDelegate()
        tableViewDelegate.delegate = selectDelegate
        
        return tableViewDelegate
    }
    
}
