//
//  ModalViewContainerManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class ModalViewContainer: NotificationContainer {
    
    // MARK: Properties
    
    var modalViewController: UIViewController?
    
    // MARK: `NotificationContainer`
    
    func present(_ viewController: UIViewController, presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentingViewController.present(viewController, animated: animated) { [weak self] in
            // Save modal view controller
            self?.modalViewController = viewController
            
            completion?()
        }
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let modalViewController = modalViewController else {
            completion?()
            return
        }
        
        modalViewController.dismiss(animated: animated) { [weak self] in
            // Discard modal view controller
            self?.modalViewController = nil
            
            completion?()
        }
    }
    
}
