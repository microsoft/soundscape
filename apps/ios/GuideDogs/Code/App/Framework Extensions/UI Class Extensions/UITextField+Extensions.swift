//
//  UITextField+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UITextField {
    func addCustomClearButton(with image: UIImage, mode: UITextField.ViewMode) {
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(image, for: .normal)
        clearButton.frame = CGRect(x: 0, y: 0, width: 27, height: 27)
        clearButton.contentMode = .center
        clearButton.addTarget(self, action: #selector(UITextField.clear(_:)), for: .touchUpInside)
        clearButton.accessibilityLabel = rightView?.accessibilityLabel
        clearButton.showsTouchWhenHighlighted = true
        clearButton.accessibilityLabel = GDLocalizedString("general.text.clear_text")
        
        rightView = clearButton
        rightViewMode = mode
    }
    
    @objc func clear(_ sender: AnyObject) {
        self.text = ""
        
        // Notify VoiceOver that it should focus on the edit field now
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self)
        
        sendActions(for: .editingChanged)
    }
}
