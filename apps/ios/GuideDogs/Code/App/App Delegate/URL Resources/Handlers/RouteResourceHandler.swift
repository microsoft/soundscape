//
//  RouteResourceHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Notification.Name {
    static let didImportRoute = Notification.Name("DidImportRoute")
    static let didFailToImportRoute = Notification.Name("DidFailToImportRoute")
}

class RouteResourceHandler: URLResourceHandler {
    
    // MARK: Keys
     
    struct Keys {
        static let route = "Route"
    }
    
    // MARK: `UniversalLinkHandler`
    
    func handleURLResource(with url: URL) {
        if let parameters = RouteParameters.decode(from: url) {
            let handler = RouteParametersHandler()
            
            handler.makeRoute(from: parameters) { [weak self] result in
                guard let `self` = self else {
                    return
                }
                
                switch result {
                case .success(let value): self.didImportRoute(route: value)
                case .failure: self.didFailToImportRoute()
                }
            }
        } else {
            didFailToImportRoute()
        }
    }
    
    private func didImportRoute(route: Route) {
        let userInfo: [String: Any] = [ Keys.route: route ]
        
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: .didImportRoute, object: self, userInfo: userInfo)
        }
    }
    
    private func didFailToImportRoute() {
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: .didFailToImportRoute, object: self)
        }
    }
    
}
