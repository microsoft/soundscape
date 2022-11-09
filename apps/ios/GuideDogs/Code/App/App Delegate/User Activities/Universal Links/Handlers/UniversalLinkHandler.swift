//
//  UniversalLinkHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol UniversalLinkHandler {
    func handleUniversalLink(with queryItems: [URLQueryItem]?, version: UniversalLinkVersion)
}
