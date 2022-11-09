//
//  UITableView+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UITableView {
    func registerCell<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func registerCell<T: UITableViewCell>(_: T.Type) where T: NibLoadableView {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func registerHeaderFooterView<T: UIView>(_: T.Type) where T: NibLoadableView {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forHeaderFooterViewReuseIdentifier: T.nibName)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        
        return cell
    }
    
    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T where T: NibLoadableView {
        guard let headerView = dequeueReusableHeaderFooterView(withIdentifier: T.nibName) as? T else {
            fatalError("Could not dequeue header view with identifier: \(T.nibName)")
        }
        
        return headerView
    }
    
    /// Returns `true` if the table view data source contains all the index paths
    func contains(indexPaths: [IndexPath]) -> Bool {
        guard let dataSource = self.dataSource else { return false }
        return !indexPaths.contains { dataSource.tableView(self, numberOfRowsInSection: $0.section) > $0.row }
    }
    
}
