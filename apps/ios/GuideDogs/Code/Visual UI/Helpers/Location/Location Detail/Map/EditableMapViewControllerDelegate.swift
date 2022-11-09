//
//  EditableMapViewControllerDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol EditableMapViewControllerDelegate: AnyObject {
    var defaultToEditMode: Bool { get }
    
    func viewController(_ viewController: UIViewController, didUpdateLocation locationDetail: LocationDetail, isAccessibilityEditing: Bool)
}

extension EditableMapViewControllerDelegate {
    
    func viewController(_ viewController: UIViewController, didUpdateLocation locationDetail: LocationDetail) {
        self.viewController(viewController, didUpdateLocation: locationDetail, isAccessibilityEditing: false)
    }
    
}
