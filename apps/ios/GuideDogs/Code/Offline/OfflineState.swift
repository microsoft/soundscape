//
//  OfflineState.swift
//  Openscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum OfflineState: String {
    case offline
    // Temporary state that openscape enters when it goes online
    case enteringOnline
    case online
}
