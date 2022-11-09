//
//  RouteLoader.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine
import CoreLocation

class RouteLoader: ObservableObject {
    let queue = DispatchQueue(label: "com.company.appname.routeloader")
    
    @Published var loadingComplete = false
    @Published var routeIDs: [String] = []
    
    private var currentSort: SortStyle = .alphanumeric
    private var tokens: [AnyCancellable] = []
    
    deinit {
        tokens.cancelAndRemoveAll()
    }
    
    func load(sort: SortStyle) {
        currentSort = sort
        
        queue.async {
            let keys = Route.objectKeys(sortedBy: sort)
            
            DispatchQueue.main.async { [weak self] in
                // Initialize routes given the sorted keys (e.g. alphanumeric or distance)
                self?.routeIDs = keys
                self?.loadingComplete = true
                self?.listenForNewRoutes()
            }
        }
    }
    
    func remove(id: String) throws {
        guard let index = routeIDs.firstIndex(where: { $0 == id }) else {
            return
        }
        
        routeIDs.remove(at: index)
        
        try Route.delete(id)
        UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("routes.action.deleted"))
    }
    
    private func listenForNewRoutes() {
        tokens.append(NotificationCenter.default.publisher(for: .routeAdded).receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.load(sort: self.currentSort)
        })
        
        tokens.append(NotificationCenter.default.publisher(for: .routeDeleted).receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.load(sort: self.currentSort)
        })
    }
}
