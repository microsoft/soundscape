//
//  RouteAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol Action {
    associatedtype State: ActionState
    associatedtype Detail
    
    static func actions(for detail: Detail) -> [State]
}

protocol ActionState {
    var isEnabled: Bool { get }
    var text: String { get }
    var accessibilityHint: String? { get }
    var icon: String { get }
    var telemetryEvent: String { get }
}

struct RouteActionState: ActionState {
    let action: RouteAction
    let isEnabled: Bool
    
    init(_ action: RouteAction, isEnabled: Bool = true) {
        self.action = action
        self.isEnabled = isEnabled
    }
    
    // MARK: Localization
    
    var text: String {
        switch action {
        case .startRoute: return GDLocalizedString("route_detail.action.start_route")
        case .stopRoute: return GDLocalizedString("route_detail.action.stop_route")
        case .startTrailActivity: return GDLocalizedString("route_detail.action.start_event")
        case .stopTrailActivity: return GDLocalizedString("route_detail.action.stop_event")
        case .resetTrailActivity: return GDLocalizedString("general.alert.reset")
        case .share: return GDLocalizedString("share.title")
        case .edit: return GDLocalizedString("route_detail.action.edit")
        }
    }
    
    var accessibilityHint: String? {
        switch action {
        case .startRoute:
            guard isEnabled else {
                return GDLocalizedString("route_detail.action.start_route.disabled.hint")
            }
            
            return GDLocalizedString("route_detail.action.start_route.hint")
            
        case .stopRoute: return GDLocalizedString("route_detail.action.stop_route.hint")
        case .startTrailActivity: return GDLocalizedString("route_detail.action.start_event.hint")
        case .stopTrailActivity: return GDLocalizedString("route_detail.action.stop_event.hint")
        case .resetTrailActivity: return GDLocalizedString("route_detail.action.reset.hint")
        case .share: return GDLocalizedString("route_detail.action.share.hint")
        case .edit: return GDLocalizedString("route_detail.action.edit.hint")
        }
    }
    
    var icon: String {
        switch action {
        case .startRoute: return "play.fill"
        case .stopRoute: return "stop.fill"
        case .startTrailActivity: return "play.fill"
        case .stopTrailActivity: return "pause.fill"
        case .resetTrailActivity: return "arrow.counterclockwise"
        case .share: return "square.and.arrow.up"
        case .edit: return "pencil"
        }
    }
    
    // MARK: Telemetry
    
    var telemetryEvent: String {
        switch action {
        case .startRoute: return "route_action.start_route"
        case .stopRoute: return "route_action.stop_route"
        case .startTrailActivity: return "route_action.start_event"
        case .stopTrailActivity: return "route_action.stop_event"
        case .resetTrailActivity: return "route_action.reset_event"
        case .share: return "route_action.share"
        case .edit: return "route_action.edit"
        }
    }
}

enum RouteAction: String, Action {
    
    case startRoute
    case stopRoute
    case startTrailActivity
    case stopTrailActivity
    case resetTrailActivity
    case share
    case edit
    
    static func actions(for detail: RouteDetail) -> [RouteActionState] {
        let isDefaultBehaviorActive = AppContext.shared.eventProcessor.activeBehavior is SoundscapeBehavior
        
        switch detail.source {
        case .database:
            if detail.isGuidanceActive {
                return [RouteActionState(.stopRoute), RouteActionState(.share)]
            } else {
                return [RouteActionState(.startRoute, isEnabled: detail.waypoints.count > 0 && isDefaultBehaviorActive ), RouteActionState(.edit), RouteActionState(.share)]
            }
            
        case .cache:
            // To enable actions, add route to Realm database
            return []
            
        case .trailActivity(let activity):
            GDLogVerbose(.routeGuidance, "Event expires: \(activity.expires), Availability: \(activity.availability)")
            
            if detail.isGuidanceActive {
                return [RouteActionState(.stopTrailActivity)]
            } else {
                return [RouteActionState(.startTrailActivity, isEnabled: isDefaultBehaviorActive && !activity.isExpired)]
            }
        }
    }
}
