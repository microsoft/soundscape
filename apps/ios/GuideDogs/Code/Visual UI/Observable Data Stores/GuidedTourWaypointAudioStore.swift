//
//  GuidedTourWaypointAudioStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

class GuidedTourWaypointAudioStore: ObservableObject {
    let id: String
    
    @Published var state: TourState?
    
    private var listeners: [AnyCancellable] = []
    
    /// Initializes a RouteGuidanceStateStore
    /// - Parameter id: The RouteDetail struct that the store object should watch
    init(_ id: String) {
        self.id = id
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorActivated).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateState()
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .tourStateChanged).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateState()
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorDeactivated).receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateState()
        })
        
        updateState()
    }
    
    init(designData id: String, state: TourState) {
        self.id = id
        self.state = state
    }
    
    deinit {
        listeners.forEach { $0.cancel() }
        listeners.removeAll()
    }
    
    private func updateState() {
        guard let tour = AppContext.shared.eventProcessor.activeBehavior as? GuidedTour else {
            state = nil
            return
        }
        
        guard tour.content.id == self.id else {
            state = nil
            return
        }
        
        self.state = tour.state
    }
}
