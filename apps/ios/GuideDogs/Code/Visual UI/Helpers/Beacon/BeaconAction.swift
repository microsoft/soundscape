//
//  BeaconAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum BeaconAction {
    
    case createMarker
    case callout
    case toggleAudio
    case moreInformation
    case remove(source: RouteDetail.Source?)
    case viewDetails
    
    static func accessibilityCustomActions(for detail: BeaconDetail) -> [BeaconAction] {
        guard detail.routeDetail == nil else {
            // Accessibility actions are not used for routes
            return []
        }
        
        if detail.locationDetail.isMarker {
            return [.callout, .toggleAudio, .remove(source: nil), .moreInformation]
        } else {
            return [.createMarker, .callout, .toggleAudio, .remove(source: nil), .moreInformation]
        }
    }
    
    // MARK: Localization
    
    var text: String {
        switch self {
        case .createMarker: return GDLocalizedString("markers.action.add_to_markers")
        case .callout: return GDLocalizedString("beacon.action.callout_beacon")
        case .toggleAudio: return GDLocalizedString("beacon.action.mute_unmute_beacon")
        case .moreInformation: return GDLocalizedString("callouts.action.more_info")
        case .remove(let source):
            guard let source = source else {
                return GDLocalizedString("beacon.action.remove_beacon")
            }
            
            switch source {
            case .trailActivity:
                return RouteActionState(.stopTrailActivity).text
            case .database, .cache:
                return RouteActionState(.stopRoute).text
            }
        case .viewDetails: return GDLocalizedString("beacon.action.view_details")
        }
    }
    
    var accessibilityHint: String? {
        switch self {
        case .createMarker: return nil
        case .callout: return nil
        case .toggleAudio: return GDLocalizedString("beacon.action.mute_unmute_beacon.acc_hint")
        case .moreInformation: return nil
        case .remove(let source):
            guard let source = source else {
                return GDLocalizedString("beacon.action.remove_beacon.double_tap.acc_hint")
            }
            
            switch source {
            case .trailActivity:
                return RouteActionState(.stopTrailActivity).accessibilityHint
            case .database, .cache:
                return RouteActionState(.stopRoute).accessibilityHint
            }
        case .viewDetails: return GDLocalizedString("beacon.action.view_details.acc_hint.details")
        }
    }
    
}
