//
//  Promise.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A minimal promise implementation which allows for asynchronously generating
/// a value (a.k.a. "fulfilling the promise").
class Promise<Value> {
    enum State<T> {
        case pending
        case resolved(T)
    }

    var state: State<Value> = .pending
    
    typealias Resolver = (Value) -> Void
    
    private let queue = DispatchQueue(label: "com.company.appname.promise")
    
    // Array of callbacks to pass the value to when fulfilling the promise
    private var callbacks: [Resolver] = []

    init(executor: (_ resolve: @escaping Resolver) -> Void) {
        executor(resolve)
    }

    /// Method for subscribing to the promise. If the promise is already in the
    /// resolved state, the resolver method passed in will be called immediately.
    /// If not, it will be stored until the value is generated and will then be
    /// called.
    ///
    /// - Parameter onResolved: A code block to call when the promise is fulfilled
    func then(onResolved: @escaping Resolver) {
        queue.sync {
            self.callbacks.append(onResolved)
            self.triggerCallbacksIfResolved()
        }
    }
    
    /// Method passed in the executor which should be called when the value has been
    /// generated and the promised should be fulfilled.
    ///
    /// - Parameter value: The value to fulfill the promise with
    private func resolve(_ value: Value) {
        updateState(to: .resolved(value))
    }

    private func updateState(to newState: State<Value>) {
        guard case .pending = state else {
            return
        }
        
        state = newState
        triggerCallbacksIfResolved()
    }

    private func triggerCallbacksIfResolved() {
        guard case let .resolved(value) = state else {
            return
        }
        
        // We trigger all the callbacks
        queue.async {
            self.callbacks.forEach { callback in callback(value) }
            self.callbacks.removeAll()
        }
    }
}
