//
//  LocationActionError.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum LocationActionError: Error {
    case failedToSaveMarker
    case markerDoesNotExist
    case failedToSetBeacon
    case failedToStartPreview
    case failedToShare
    
    var localizedDescription: String {
        switch self {
        case .failedToSaveMarker: return GDLocalizedString("general.error.add_marker_error")
        case .markerDoesNotExist: return GDLocalizedString("general.error.add_marker_error")
        case .failedToSetBeacon: return GDLocalizedString("general.error.set_beacon_error")
        case .failedToStartPreview: return GDLocalizedString("general.error.preview")
        case .failedToShare: return GDLocalizedString("universal_links.alert.share_error.message")
        }
    }
}
