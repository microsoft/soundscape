//
//  MessageUI+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  This extension restores the title attriblues to the mail and SMS compose view controllers.
//  This is a hack so they will not get the app's default theme title color.

import MessageUI

private let defaultTitleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.darkText]

extension MFMailComposeViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.titleTextAttributes = defaultTitleAttributes
    }
    
}

extension MFMessageComposeViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.titleTextAttributes = defaultTitleAttributes
    }
    
}
