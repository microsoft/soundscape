//
//  GenericTableViewDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// This class is designed to reduce repeating code when creating a table view.
/// This class implements the `UITableViewDelegate` methods, including configuring a custom header view.
class GenericTableViewDelegate<HeaderConfigurator: TableViewHeaderViewConfigurator>: TableViewDelegate {
    
    // MARK: Properties
    
    private let headerViewConfigurator: HeaderConfigurator
    private var didRegisterHeaderFooterView = false
    
    // MARK: Initialization
    
    private init(headerViewConfigurator: HeaderConfigurator) {
        self.headerViewConfigurator = headerViewConfigurator
        
        super.init()
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let dataSource = tableView.dataSource as? TableViewDataSourceProtocol, let header = dataSource.header(in: section) else {
            return nil
        }
        
        if didRegisterHeaderFooterView == false {
            // Register header
            tableView.registerHeaderFooterView(HeaderConfigurator.TableViewHeader.self)
            didRegisterHeaderFooterView = true
        }
     
        let headerView: HeaderConfigurator.TableViewHeader = tableView.dequeueReusableHeaderFooterView()
        headerViewConfigurator.configure(headerView, forDisplaying: header)
        
        return headerView
     }
    
}

extension GenericTableViewDelegate where HeaderConfigurator == POITableViewHeaderViewConfigurator {
    
    static func make(selectDelegate: TableViewSelectDelegate) -> GenericTableViewDelegate {
        // Create configurator for header view
        let configurator = POITableViewHeaderViewConfigurator()
        
        let tableViewDelegate = GenericTableViewDelegate(headerViewConfigurator: configurator)
        tableViewDelegate.delegate = selectDelegate
        
        return tableViewDelegate
    }
    
}

extension GenericTableViewDelegate where HeaderConfigurator == FilterTableViewHeaderViewConfigurator {
    
    static func make(selectDelegate: TableViewSelectDelegate, filterDelegate: FilterTableViewHeaderViewDelegate, filterAction: FilterTableViewHeaderView.Action?) -> GenericTableViewDelegate {
        // Create configurator for header view
        let configurator = FilterTableViewHeaderViewConfigurator()
        configurator.delegate = filterDelegate
        configurator.action = filterAction
        
        let tableViewDelegate = GenericTableViewDelegate(headerViewConfigurator: configurator)
        tableViewDelegate.delegate = selectDelegate
        
        return tableViewDelegate
    }
    
}
