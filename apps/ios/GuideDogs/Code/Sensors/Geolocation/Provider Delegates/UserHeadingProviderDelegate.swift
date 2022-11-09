//
//  UserHeadingProviderDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol UserHeadingProviderDelegate: AnyObject {
    func userHeadingProvider(_ provider: UserHeadingProvider, didUpdateUserHeading heading: HeadingValue?)
}
