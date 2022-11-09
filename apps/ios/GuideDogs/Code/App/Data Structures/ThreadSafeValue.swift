//
//  ThreadSafeValue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

//
// This class wraps the access methods for the given value
// in a thread-safe, concurrent queue
//
// Read access is done synchronously
// Write access is done asynchronously with a barrier
//
class ThreadSafeValue<T> {
    
    // MARK: Properties
    
    private let queue: DispatchQueue
    private var _value: T?
    
    var value: T? {
        get {
            var value: T?
            
            // Read synchronously
            queue.sync {
                value = _value
            }
            
            return value
        }
        
        set {
            // Write asynchronously with barrier
            queue.async(flags: .barrier) { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self._value = newValue
            }
        }
    }
    
    // MARK: Initialization
    
    init(_ value: T? = nil, qos: DispatchQoS) {
        // Save initial value
        _value = value
        
        // Initialize queue
        queue = DispatchQueue(label: "com.company.appname.threadsafevalue", qos: qos, attributes: .concurrent)
    }
    
}
