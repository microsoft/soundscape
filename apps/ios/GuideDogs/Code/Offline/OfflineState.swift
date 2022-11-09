//
//  OfflineState.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum OfflineState: String {
    case offline
    // Temporary state that Soundscape enters when it goes online
    case enteringOnline
    case online
}
