//
//  UISearchController+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UISearchController {
    
    convenience init?(delegate: SearchResultsTableViewControllerDelegate) {
        let storyboard = UIStoryboard(name: "POITable", bundle: nil)
        
        // Initialize search results controller
        guard let searchResultsController = storyboard.instantiateViewController(withIdentifier: "SearchResultsTableView")
                as? SearchResultsTableViewController else { return nil }
        
        self.init(searchResultsController: searchResultsController, delegate: delegate)
    }
    
    /// - Note: When `displayInPlace` is `false` (default) the `UISearchController` uses the `searchResultsController` argument as it's property.
    /// When the value is `true`, that value will be `nil`.
    convenience init(searchResultsController: SearchResultsTableViewController,
                     delegate: SearchResultsTableViewControllerDelegate,
                     displayInPlace: Bool = false) {
        // Pass `delegate` to new view
        searchResultsController.delegate = delegate
        
        // Initialize search controller
        self.init(searchResultsController: displayInPlace ? nil : searchResultsController)
        
        self.searchResultsUpdater = searchResultsController.searchResultsUpdater
        // Configure `UISearchBar`
        self.searchBar.delegate = searchResultsController.searchResultsUpdater
        self.searchBar.placeholder = GDLocalizedString("search.choose_destination")
        self.searchBar.searchTextField.textColor = Colors.Background.secondary
        self.searchBar.searchTextField.tintColor = Colors.Background.secondary
        self.searchBar.searchTextField.backgroundColor = UIColor.white
        // Immediately show the results controller when the search controller is active
        self.showsSearchResultsController = true
    }
    
}
