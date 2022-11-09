//
//  BehaviorDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol BehaviorDelegate: AnyObject {
    func interruptCurrent(clearQueue: Bool, playHush: Bool)
    func process(_ event: Event)
}
