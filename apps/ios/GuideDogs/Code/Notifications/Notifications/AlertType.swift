//
//  AlertType.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// `RawValue` determines which notification to display if multiple
/// notifications can be displayed in the same container
///
enum AlertType: Int, NotificationProtocol {
    case offline
    case shareMarker
    case push
    case deviceReachability
    case shareRoute
    
    static var container: NotificationContainer {
        return AlertContainer()
    }
    
    var observer: NotificationObserver {
        switch self {
        case .offline: return OfflineAlertObserver()
        case .shareMarker: return ShareMarkerAlertObserver()
        case .push: return PushAlertObserver()
        case .deviceReachability: return DeviceReachabilityAlertObserver()
        case .shareRoute: return ShareRouteAlertObserver()
        }
    }
}
