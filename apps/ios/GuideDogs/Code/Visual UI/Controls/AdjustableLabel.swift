//
//  AdjustableLabel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol AdjustableLabelDelegate: AnyObject {
    func onAccessibilityIncrement()
    func onAccessibilityDecrement()
}

class AdjustableLabel: UILabel {
    weak var delegate: AdjustableLabelDelegate?
    
    override func accessibilityIncrement() {
        delegate?.onAccessibilityIncrement()
    }
    
    override func accessibilityDecrement() {
        delegate?.onAccessibilityDecrement()
    }
}
