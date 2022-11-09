//
//  AutomaticGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol AutomaticGenerator {
    /// Indicates if this automatic callout generator is allowed to interrupt other callouts
    /// that are already playing when it generates callouts. This should be used for
    /// automatic callout generators related to safety or critical information.
    var canInterrupt: Bool { get }
    
    /// Can be called by other `AutomaticGenerator`'s to signal that they have already generated
    /// a callout for a particular entity so no additional callouts should be generated.
    ///
    /// - Parameter id: ID/Key of the entity that was called out
    func cancelCalloutsForEntity(id: String)
    
    func respondsTo(_ event: StateChangedEvent) -> Bool
    
    func handle(event: StateChangedEvent, verbosity: Verbosity) -> HandledEventAction?
}
