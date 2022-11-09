//
//  NotificationContainerManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class NotificationContainerManager<T: NotificationProtocol> {
    
    private var currentViewController: UIViewController?
    private let server: NotificationServer<T>
    private var container: NotificationContainer
    
    init(_ notifications: [T]) {
        self.server = NotificationServer(notifications)
        self.container = T.container
        
        // Initialize `NotificationServerDelegate`
        server.delegate = self
    }
    
    func viewControllerWillChange(_ viewController: UIViewController) {
        self.currentViewController = viewController
        
        updateContainer(in: viewController)
    }
    
    private func updateContainer(in viewController: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            self?.container.dismiss(animated: true) { [weak self] in
                guard let notificationViewController = self?.server.requestNotification(in: viewController) else {
                    return
                }
                
                self?.container.present(notificationViewController, presentingViewController: viewController)
            }
        }
    }
    
}

extension NotificationContainerManager: NotificationServerDelegate {
    
    func stateDidChange<T>(_ server: NotificationServer<T>) where T: NotificationProtocol {
        guard let viewController = currentViewController else {
            return
        }
        
        updateContainer(in: viewController)
    }
    
    func performSegue<T>(_ server: NotificationServer<T>, destination: ViewControllerRepresentable) where T: NotificationProtocol {
        guard let navigationController: NavigationController = currentViewController?.navigationController as? NavigationController else {
            return
        }
        
        navigationController.performSegue(destination)
    }
    
    func popToRootViewController<T>(_ server: NotificationServer<T>) where T: NotificationProtocol {
        currentViewController?.navigationController?.popToRootViewController(animated: true)
    }
    
}
