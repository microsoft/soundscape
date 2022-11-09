//
//  OfflineBannerViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class OfflineBannerViewController: BannerViewController {
    
    // MARK: `OfflineBannerViewController` State
    
    enum State {
        case `default`
        case searchTableView
        case nearbyTableView
        case offlineHelpView
        
        var nibName: String {
            switch self {
            case .default: return "OfflineDefaultBanner"
            case .searchTableView: return "OfflineSearchBanner"
            case .nearbyTableView: return "OfflineSearchBanner"
            case .offlineHelpView: return "OfflineHelpBanner"
            }
        }
        
        var segue: ViewControllerRepresentable? {
            switch self {
            case .default: return AnyViewControllerRepresentable.offlineHelp
            case .searchTableView: return AnyViewControllerRepresentable.offlineHelp
            case .nearbyTableView: return AnyViewControllerRepresentable.offlineHelp
            case .offlineHelpView: return nil
            }
        }
        
        init(in viewController: UIViewController) {
            if viewController is SearchTableViewController || viewController is SearchResultsTableViewController {
                self = .searchTableView
            } else if viewController is NearbyTableViewController || viewController is NearbyFilterTableViewController {
                self = .nearbyTableView
            } else if viewController is OfflineHelpPageViewController {
                self = .offlineHelpView
            } else {
                self = .default
            }
        }
    }
    
    // MARK: Properties
    
    var segue: ViewControllerRepresentable?
    
    // MARK: Initialization
    
    convenience init(in viewController: UIViewController) {
        // Determine the state of the banner view
        // controller
        let state = State(in: viewController)
        
        // Initialize `self`
        self.init(nibName: state.nibName)
        self.segue = state.segue
    }
    
}
