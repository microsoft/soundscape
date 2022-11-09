//
//  SmallBanner.swift
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
enum SmallBanner: Int, NotificationProtocol {
    case routeGuidance
    
    static var container: NotificationContainer {
        return BannerContainer(type: .small)
    }
    
    var observer: NotificationObserver {
        switch self {
        case .routeGuidance: return RouteGuidanceBannerObserver()
        }
    }
}
