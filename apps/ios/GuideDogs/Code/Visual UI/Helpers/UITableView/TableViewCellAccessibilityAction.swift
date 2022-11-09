//
//  TableViewCellAccessibilityAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class TableViewCellAccessibilityAction<ObjectType: Any, CellType: Any>: UIAccessibilityCustomAction {
    var object: ObjectType?
    
    let shouldAttach: ((CellType) -> Bool)
    
    let canShowInActionSheet: Bool
    
    init(name: String, target: Any?, selector: Selector, actionSheet: Bool = false, _ activationCondition: ((CellType) -> Bool)? = nil) {
        let defaultActivationCondition: (CellType) -> Bool = { (_) in
            return true
        }
        
        shouldAttach = activationCondition ?? defaultActivationCondition
        canShowInActionSheet = actionSheet
        
        super.init(name: name, target: target, selector: selector)
    }
}
