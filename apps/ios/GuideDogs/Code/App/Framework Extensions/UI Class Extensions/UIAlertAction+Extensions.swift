//
//  UIAlertAction+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension UIAlertAction {
    /// Create and return an action that opens a resource at the specified URL
    /// - returns: A `UIAlertAction` or `nil` if there is no app available to handle the URL
    convenience init?(title: String, url: URL, handler: (() -> Void)? = nil) {
        guard UIApplication.shared.canOpenURL(url) else {
            return nil
        }
        
        self.init(title: title, style: .default) { (_) in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            handler?()
        }
    }
}
