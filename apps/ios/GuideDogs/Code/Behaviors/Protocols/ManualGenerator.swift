//
//  ManualGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol ManualGenerator {
    func respondsTo(_ event: UserInitiatedEvent) -> Bool
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction?
}
