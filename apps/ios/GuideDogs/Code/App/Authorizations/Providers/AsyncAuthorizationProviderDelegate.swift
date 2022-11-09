//
//  AsyncAuthorizationProviderDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol AsyncAuthorizationProviderDelegate: AnyObject {
    func authorizationDidChange(_ authorization: AuthorizationStatus)
}
