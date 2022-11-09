//
//  LinkedList.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class LinkedListNode<T> {
    var value: T
    
    var next: LinkedListNode<T>?
    
    weak var previous: LinkedListNode<T>?
    
    init(_ value: T) {
        self.value = value
    }
}

class LinkedList<T> {
    private(set) var count = 0
    
    var isEmpty: Bool {
        return first == nil
    }
    
    private(set) var first: LinkedListNode<T>?
    
    private(set) weak var last: LinkedListNode<T>?
    
    func append(_ value: T) {
        let node = LinkedListNode(value)
        
        if let tail = last {
            node.previous = tail
            tail.next = node
        } else {
            first = node
        }
        
        last = node
        
        count += 1
    }
    
    func node(at: Int) -> LinkedListNode<T>? {
        guard at >= 0 else {
            return nil
        }
        
        var node = first
        var index = at
        
        while node != nil {
            guard index > 0 else {
                return node
            }
            
            index -= 1
            node = node?.next
        }
        
        return nil
    }
    
    func clear() {
        first = nil
        last = nil
        count = 0
    }
    
    func remove(_ node: LinkedListNode<T>) -> T {
        let previous = node.previous
        let next = node.next
        
        if let prev = previous {
            prev.next = next
        } else {
            first = next
        }
        next?.previous = previous
        
        if next == nil {
            last = previous
        }
        
        count -= 1
        
        node.previous = nil
        node.next = nil
        
        return node.value
    }
}
