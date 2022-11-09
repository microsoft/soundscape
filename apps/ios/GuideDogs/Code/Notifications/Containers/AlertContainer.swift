//
//  AlertContainerManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class AlertContainer: NotificationContainer {
    
    // MARK: Properties
    
    private var alertController: UIAlertController?
    
    // MARK: `NotificationContainer`
    
    func present(_ viewController: UIViewController, presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let alertController = viewController as? UIAlertController else {
            completion?()
            return
        }
        
        guard alertController.presentingViewController == nil else {
            completion?()
            return
        }
        
        presentingViewController.present(alertController, animated: animated) { [weak self] in
            // Save alert controller
            self?.alertController = alertController
            
            completion?()
        }
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let alertController = alertController else {
            completion?()
            return
        }
        
        if alertController.presentingViewController == nil {
            // Discard alert controller
            self.alertController = nil
                       
            completion?()
        } else {
            alertController.dismiss(animated: animated) { [weak self] in
                // Discard alert controller
                self?.alertController = nil
                           
                completion?()
            }
        }
    }
    
}
