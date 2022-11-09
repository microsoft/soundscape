//
//  CalloutHistory.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

protocol CalloutHistoryDelegate: AnyObject {
    func onCalloutInserted(_ callout: CalloutProtocol)
    func onCalloutRemoved(_ callout: CalloutProtocol)
    func onHistoryCleared()
}

class CalloutHistory {
    weak var delegate: CalloutHistoryDelegate? {
        didSet {
            // Make sure that we call `onCalloutInserted` for every callout once. This
            // ensures that if a callout is inserted before the delegate is attached,
            // the delegate will still be informed of it.
            
            for callout in calloutStack.elements {
                delegate?.onCalloutInserted(callout)
            }
        }
    }
    
    var maxItems: UInt {
        return calloutStack.bound
    }
    
    private var calloutStack: BoundedStack<CalloutProtocol>
    
    public var callouts: [CalloutProtocol] {
        return calloutStack.elements
    }
    
    init(maxItems: UInt = 10) {
        calloutStack = BoundedStack<CalloutProtocol>(bound: maxItems)
    }
    
    func insert(_ callout: CalloutProtocol) {
        guard callout.includeInHistory else {
            return
        }
        
        calloutStack.push(callout)
        delegate?.onCalloutInserted(callout)
    }
    
    func insert<T: CalloutProtocol>(contentsOf array: [T]) {
        let callouts = array.filter({ $0.includeInHistory })
        
        guard callouts.count > 0 else {
            return
        }
        
        calloutStack.push(contentsOf: callouts)
        
        for callout in callouts {
            delegate?.onCalloutInserted(callout)
        }
    }
    
    func visibleIndex(of callout: CalloutProtocol) -> Int? {
        guard callout.includeInHistory else {
            return nil
        }
        
        return calloutStack.elements.filter({$0.includeInHistory}).reversed().firstIndex(where: { $0.equals(rhs: callout) })
    }
    
    func remove(where predicate: (CalloutProtocol) -> Bool) {
        for removedItem in calloutStack.remove(where: predicate) {
            delegate?.onCalloutRemoved(removedItem)
        }
    }
    
    func clear() {
        calloutStack.clear()
        delegate?.onHistoryCleared()
    }
}
