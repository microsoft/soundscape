//
//  RouteGuidanceStateStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

class RouteGuidanceStateStore: ObservableObject {
    let id: String
    
    @Published var state: RouteGuidanceState?
    
    private var listeners: [AnyCancellable] = []
    
    /// Initializes a RouteGuidanceStateStore
    /// - Parameter id: The RouteDetail struct that the store object should watch
    init(_ id: String) {
        self.id = id
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorActivated).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateState()
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .routeGuidanceStateChanged).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateState()
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorDeactivated).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateState()
        })
        
        updateState()
    }
    
    init(designData id: String, state: RouteGuidanceState) {
        self.id = id
        self.state = state
    }
    
    deinit {
        listeners.forEach { $0.cancel() }
        listeners.removeAll()
    }
    
    private func updateState() {
        guard let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            state = nil
            return
        }
        
        guard routeGuidance.content.id == self.id else {
            state = nil
            return
        }
        
        self.state = routeGuidance.state
    }
}
