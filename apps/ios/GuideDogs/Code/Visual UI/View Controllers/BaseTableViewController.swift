//
//  BaseTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class BaseTableViewController: UITableViewController {

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem

        self.tableView.backgroundColor = Colors.Background.quaternary
        self.tableView.separatorColor = Colors.Background.secondary
    }

    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }

        view.textLabel?.textColor = Colors.Foreground.primary
        view.backgroundView?.backgroundColor = Colors.Background.quaternary
        
        if let text = view.textLabel?.text, text.lowercased().contains("callout") {
            view.accessibilityLabel = text.lowercased().replacingOccurrences(of: "callout", with: "call out")
        } else {
            view.accessibilityLabel = view.textLabel?.text
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        
        view.textLabel?.textColor = Colors.Foreground.primary
        view.backgroundView?.backgroundColor = Colors.Background.quaternary
        
        if let text = view.textLabel?.text, text.lowercased().contains("callout") {
            view.accessibilityLabel = text.lowercased().replacingOccurrences(of: "callout", with: "call out")
        } else {
            view.accessibilityLabel = view.textLabel?.text
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.textColor = Colors.Foreground.primary
        cell.detailTextLabel?.textColor = Colors.Foreground.secondary

        cell.imageView?.tintColor = Colors.Foreground.primary
        // Reload the image for the tint to take effect
        cell.imageView?.image = cell.imageView?.image?.withRenderingMode(.alwaysTemplate)

        cell.backgroundColor = Colors.Background.primary
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}
