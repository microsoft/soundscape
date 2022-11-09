//
//  BehaviorProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

protocol Behavior: AnyObject, CustomStringConvertible {
    var id: UUID { get }
    var isActive: Bool { get }
    var verbosity: Verbosity { get }
    var userLocation: CLLocation? { get }
    
    // MARK: - Generators
    
    var manualGenerators: [ManualGenerator] { get }
    var autoGenerators: [AutomaticGenerator] { get }
    
    // MARK: - Interaction with Event Processor and Parent Behaviors
    
    var delegate: BehaviorDelegate? { get set }
    var parent: Behavior? { get }
    
    /// Set of automatic generator types in the parent behavior chain that should be blocked when
    /// this generator is active. This property can be used in custom behaviors to ensure that the
    /// default implementation of automatic callouts or beacon callouts are blocked in favor of the
    /// behavior's custom implementation of either.
    var blockedAutoGenerators: [AutomaticGenerator.Type] { get }
    
    /// Set of manual generator types in the parent behavior chain that should be blocked when
    /// this generator is active. This property can be used in custom behaviors to ensure that the
    /// default implementation of beacon callouts or exploration modes are blocked in favor of the
    /// behavior's custom implementation of either.
    var blockedManualGenerators: [ManualGenerator.Type] { get }
    
    // MARK: - Helpers
    
    func addBlocked(auto gen: AutomaticGenerator.Type)
    func removeBlocked(auto gen: AutomaticGenerator.Type)
    func addBlocked(manual gen: ManualGenerator.Type)
    func removeBlocked(manual gen: ManualGenerator.Type)
    
    // MARK: - Lifecycle
    
    func activate(with parent: Behavior?)
    func willDeactivate()
    func deactivate() -> Behavior?
    func sleep()
    func wake()
    
    // MARK: - Event Handling
    
    func handleEvent(_ event: Event, blockedAuto: [AutomaticGenerator.Type], blockedManual: [ManualGenerator.Type], completion: @escaping ([HandledEventAction]?) -> Void)
}

extension Behavior {
    func handleEvent(_ event: Event, blockedAutoGenerators: [AutomaticGenerator.Type] = [], blockedManualGenerators: [ManualGenerator.Type] = [], completion: @escaping ([HandledEventAction]?) -> Void) {
        self.handleEvent(event, blockedAuto: blockedAutoGenerators, blockedManual: blockedManualGenerators, completion: completion)
    }
}
