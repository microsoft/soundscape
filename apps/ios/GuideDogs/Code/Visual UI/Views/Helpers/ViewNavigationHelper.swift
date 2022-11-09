//
//  ViewNavigationHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

enum NavigationAction {
    case popViewController
    case popToRootViewController
    case popToViewController(type: UIViewController.Type)
    case dismissesViewController
}

class ViewNavigationHelper: ObservableObject {
    weak var host: UIHostingController<AnyView>?
    
    @Binding var isActive: Bool
    
    /// Use this initializer if the parent of the view is a HostingViewController
    init() {
        _isActive = .constant(true)
    }
    
    /// Use this initializer if the parent of the view is a SwiftUI View. For the time being, if any of the
    /// navigation methods are called, the isActive binding will simply be set to false, returning the user
    /// to the parent view of this view.
    ///
    /// - Parameter isActive: Binding to a Bool used to activate the navigation link to the view that uses
    ///                       this navigation helper
    init(isActive: Binding<Bool>) {
        _isActive = isActive
    }
    
    func popToRootViewController(animated: Bool) {
        guard let host = host else {
            isActive = false
            return
        }
        
        host.navigationController?.popToRootViewController(animated: animated)
    }
    
    func popToViewController(ofType: UIViewController.Type, animated: Bool) {
        guard let host = host else {
            isActive = false
            return
        }
        
        // Find the most recent vc of the provided type
        guard let vc = host.navigationController?.viewControllers.last(where: { ofType == type(of: $0) }) else {
            // If there wasn't a VC of this type, pop all the way to the root
            host.navigationController?.popToRootViewController(animated: animated)
            return
        }
        
        host.navigationController?.popToViewController(vc, animated: animated)
    }
    
    func popViewController(animated: Bool) {
        guard let host = host else {
            isActive = false
            return
        }
        
        host.navigationController?.popViewController(animated: animated)
    }
    
    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard let host = host else {
            isActive = false
            return
        }
        
        host.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let host = host else {
            isActive = false
            return
        }
        
        host.present(viewController, animated: animated, completion: completion)
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let host = host else {
            isActive = false
            return
        }
        
        host.dismiss(animated: flag, completion: completion)
    }
    
    func onNavigationAction(_ action: NavigationAction) {
        switch action {
        case .popViewController:
            popViewController(animated: true)
            
        case .popToRootViewController:
            popToRootViewController(animated: true)
            
        case .popToViewController(let type):
            popToViewController(ofType: type, animated: true)
            
        case .dismissesViewController:
            dismiss(animated: true)
        }
    }
}
