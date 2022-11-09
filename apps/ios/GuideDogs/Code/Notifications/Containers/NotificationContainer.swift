//
//  NotificationContainer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol NotificationContainer {
    func present(_ viewController: UIViewController, presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

extension NotificationContainer {
    
    func present(_ viewController: UIViewController, presentingViewController: UIViewController) {
        return present(viewController, presentingViewController: presentingViewController, animated: true, completion: nil)
    }
    
    func dismiss() {
        return dismiss(animated: true, completion: nil)
    }
    
}
