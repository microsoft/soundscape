//
//  Queue.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct Queue<T> {
    
    // MARK: Properties
    
    private var list: LinkedList<T>
    
    private let queue = DispatchQueue(label: "com.company.appname.queue")
    
    var count: Int {
        return queue.sync {
            return list.count
        }
    }
    
    var isEmpty: Bool {
        return queue.sync {
            return list.isEmpty
        }
    }
    
    // MARK: Initialization
    
    init() {
        list = LinkedList<T>()
    }
    
    // MARK: -
    
    public mutating func enqueue(_ value: T) {
        queue.sync {
            list.append(value)
        }
    }
    
    public mutating func dequeue() -> T? {
        return queue.sync { () -> T? in
            guard let item = list.first else {
                return nil
            }
            
            return list.remove(item)
        }
    }
    
    public mutating func clear() {
        queue.sync {
            list.clear()
        }
    }
    
    public func peek() -> T? {
        return queue.sync {
            return list.first?.value
        }
    }
}
