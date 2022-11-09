//
//  NavigationController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class NavigationController: UINavigationController {
    
    // MARK: Properties
    
    private var notificationController = NotificationController.shared
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = notificationController
        
        // Default navigation bar
        navigationBar.configureAppearance(for: .default)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let first = viewControllers.first, first.isViewLoaded else {
            return
        }
        
        // If the navigation controller is appearing, but the top view controller has
        // already been loaded, then manually notify the notification controller
        notificationController.navigationController(self, willShow: first, animated: true)
    }
    
}

extension NavigationController {
    
    func performSegue(_ destination: ViewControllerRepresentable) {
        guard let viewController = destination.makeViewController() else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.pushViewController(viewController, animated: true)
        }
    }
    
}
