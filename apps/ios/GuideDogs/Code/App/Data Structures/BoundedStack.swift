//
//  BoundedStack.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

public struct BoundedStack<T> {
    private(set) var bound: UInt
    private(set) var elements: [T] = []
    
    public init(bound: UInt) {
        if bound == 0 {
            fatalError("The BoundedStack must have a bound greater than zero!")
        }
        
        self.bound = bound
    }
    
    // MARK: Stack manipulation
    
    public mutating func push(_ value: T) {
        elements.append(value)
        
        if elements.count > bound {
            elements.removeFirst()
        }
    }
    
    public mutating func push(contentsOf array: [T]) {
        elements.append(contentsOf: array)
        
        if elements.count > bound {
            elements.removeFirst(elements.count - Int(bound))
        }
    }
    
    public mutating func pop() -> T? {
        guard !elements.isEmpty else {
            return nil
        }
        
        return elements.removeLast()
    }
    
    public mutating func remove(where predicate: (T) -> Bool) -> [T] {
        var removed: [T] = []
        
        while let index = elements.firstIndex(where: predicate) {
            removed.append(elements.remove(at: index))
        }
        
        return removed
    }
    
    public mutating func clear() {
        elements.removeAll()
    }
    
    public func peek() -> T? {
        return elements.last
    }
    
    public var isEmpty: Bool { return elements.isEmpty }
    
    public var count: Int { return elements.count }
}
