//
//  UINavigationItem+Extension.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UINavigationItem {
    
    /// Remove a barButtonItem from the right or left items if exists
    func remove(barButtonItem: UIBarButtonItem) {
        if barButtonItem == self.rightBarButtonItem {
            self.rightBarButtonItem = nil
        } else if barButtonItem == self.leftBarButtonItem {
            self.leftBarButtonItem = nil
        } else if var rightBarButtonItems = self.rightBarButtonItems,
            let index = rightBarButtonItems.firstIndex(of: barButtonItem) {
            rightBarButtonItems.remove(at: index)
            self.rightBarButtonItems = rightBarButtonItems
        } else if var leftBarButtonItems = self.leftBarButtonItems,
            let index = leftBarButtonItems.firstIndex(of: barButtonItem) {
            leftBarButtonItems.remove(at: index)
            self.leftBarButtonItems = leftBarButtonItems
        }
    }
    
}
