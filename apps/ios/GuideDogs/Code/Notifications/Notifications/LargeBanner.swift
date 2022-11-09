//
//  LargeBanner.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// `RawValue` determines which notification to display if multiple
/// notificaitons can be displayed in the same container
///
enum LargeBanner: Int, NotificationProtocol {
    case offline
    
    static var container: NotificationContainer {
        return BannerContainer(type: .large)
    }
    
    var observer: NotificationObserver {
        switch self {
        case .offline: return OfflineBannerObserver()
        }
    }
}
