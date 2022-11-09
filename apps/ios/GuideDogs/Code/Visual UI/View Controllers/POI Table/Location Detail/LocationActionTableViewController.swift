//
//  LocationActionTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class LocationActionTableViewController: UITableViewController {
    
    // MARK: Properties
    
    private static let prototypeCellIdentifier = "ActionCell"
    
    private let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "DefaultCell")
    weak var delegate: LocationActionDelegate?
    
    var locationDetail: LocationDetail? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            tableView.reloadData()
        }
    }
    
    private var actions: [LocationAction] {
        guard let locationDetail = locationDetail else {
            return []
        }
        
        return LocationAction.actions(for: locationDetail)
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        preferredContentSize.height = UIView.preferredContentHeight(for: tableView)
    }
    
    // MARK: `UITableViewDataSource`
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard locationDetail != nil else {
            return 0
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard locationDetail != nil else {
            return 0
        }
        
        guard section == 0 else {
            return 0
        }
        
        return actions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            return defaultCell
        }
        
        guard indexPath.row < actions.count else {
            return defaultCell
        }
        
        let action = actions[indexPath.row]
        
        let identifier = LocationActionTableViewController.prototypeCellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.textLabel?.text = action.text
        cell.accessibilityHint = action.accessibilityHint
        cell.accessibilityIdentifier = action.accessibilityIdentifier
        cell.imageView?.image = action.image
        
        if action.isEnabled {
            cell.selectionStyle = .default
            cell.textLabel?.isEnabled = true
            cell.imageView?.alpha = 1.0
        } else {
            cell.selectionStyle = .none
            cell.textLabel?.isEnabled = false
            cell.imageView?.alpha = 0.4
        }
        
        // Image view will scale with content size
        cell.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        
        return cell
    }
    
    // MARK: `UITableViewDelegate`
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard indexPath.section == 0 else {
            return
        }
        
        guard indexPath.row < actions.count else {
            return
        }
        
        guard let delegate = delegate else {
            return
        }
        
        guard let detail = locationDetail else {
            return
        }
        
        let action = actions[indexPath.row]
        
        guard action.isEnabled else {
            return
        }
        
        delegate.didSelectLocationAction(action, detail: detail)
    }
    
}
