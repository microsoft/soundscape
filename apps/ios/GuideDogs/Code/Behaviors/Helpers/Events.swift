//
//  Events.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

enum EventType {
    case userInitiated
    case stateChanged
}

enum EventDistribution {
    /// Event should be passed to all generators that respond to this event type
    case broadcast
    
    /// Event should be passed to the first generator that responds to this event type
    case consumed
}

protocol Event {
    var type: EventType { get }
    
    var name: String { get }
    
    /// By default, events should be blockable. In some rare cases, this property should be set to `false`
    /// so as to allow the event to be passed to a generator that can handle it regardless of whether or
    /// not the owning behavior is currently blocking that generator. This is useful for system events
    /// that are designed to propagate global state change information to every generator.
    var blockable: Bool { get }
}

extension Event {
    var blockable: Bool {
        return true
    }
    
    var name: String {
        guard Mirror(reflecting: self).displayStyle == .class else {
            // The event is a struct
            return "\(String(describing: self).split(separator: "(").first ?? "UnknownEvent")"
        }
        
        // The event is a class
        return String(describing: self).split(separator: ".").dropFirst().joined(separator: ".")
    }
}

protocol StateChangedEvent: Event {
    var distribution: EventDistribution { get }
}

extension StateChangedEvent {
    var type: EventType {
        return .stateChanged
    }
    
    var distribution: EventDistribution {
        return .consumed
    }
}

protocol UserInitiatedEvent: Event { }

extension UserInitiatedEvent {
    var type: EventType {
        return .userInitiated
    }
}

// MARK: General UI Events

class BehaviorActivatedEvent: UserInitiatedEvent { }

class BehaviorDeactivatedEvent: UserInitiatedEvent {
    var completionHandler: ((Bool) -> Void)?
    
    init(completionHandler: ((Bool) -> Void)? = nil) {
        self.completionHandler = completionHandler
    }
}

// MARK: General State Change Events

class LocationUpdatedEvent: StateChangedEvent {
    var distribution: EventDistribution = .broadcast
    
    let location: CLLocation
    
    init(_ location: CLLocation) {
        self.location = location
    }
}

/// A state change event that allows any generator that needs to to reset its
/// state when a simulation starts.
class GPXSimulationStartedEvent: StateChangedEvent {
    // Ensure that all generators listening for this event receive it since it allows
    // them to reset state when a simulation starts
    let distribution: EventDistribution = .broadcast
}
