//
//  AsyncAuthorizationProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol AsyncAuthorizationProvider: AuthorizationProvider {
    var authorizationDelegate: AsyncAuthorizationProviderDelegate? { get set }
}
