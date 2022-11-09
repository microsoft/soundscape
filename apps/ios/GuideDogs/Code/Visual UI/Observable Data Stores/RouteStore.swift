//
//  RouteStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

class RouteStore: ObservableObject {
    private(set) var detail: RouteDetail
    
    private var tokens: [AnyCancellable] = []
    
    init(_ detail: RouteDetail) {
        self.detail = detail
            
        tokens.append(NotificationCenter.default.publisher(for: .markerAdded).receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        }))
        
        tokens.append(NotificationCenter.default.publisher(for: .markerUpdated).receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        }))
        
        tokens.append(NotificationCenter.default.publisher(for: .routeUpdated).receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        }))
    }
    
    deinit {
        tokens.cancelAndRemoveAll()
    }
    
    func update(_ detail: RouteDetail) {
        self.detail = detail
        objectWillChange.send()
    }
}
