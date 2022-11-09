//
//  QueueAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Indicates how a set of callouts should be enqueued in the callout queue.
enum QueueAction {
    /// The current callout is interrupted (if one exists), the queue is cleared, and the new callouts are enqueued
    case interruptAndClear
    
    /// The queue is cleared (but the current callout is not interrupted), and the new callouts are enqueued
    case clear
    
    /// The new callouts are enqueued
    case enqueue
}
