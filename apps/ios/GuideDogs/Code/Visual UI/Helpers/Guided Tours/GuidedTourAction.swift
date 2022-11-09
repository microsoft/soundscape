//
//  GuidedTourAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

struct GuidedTourActionState: ActionState {
    let action: GuidedTourAction
    let isEnabled: Bool
    
    init(_ action: GuidedTourAction, isEnabled: Bool = true) {
        self.action = action
        self.isEnabled = isEnabled
    }
    
    // MARK: Localization
    
    var text: String {
        switch action {
        case .startTour: return GDLocalizedString("route_detail.action.start_event")
        case .stopTour: return GDLocalizedString("route_detail.action.stop_event")
        case .checkForUpdates: return GDLocalizedString("behavior.experiences.reset_and_update_action")
        }
    }
    
    var accessibilityHint: String? {
        switch action {
        case .startTour: return GDLocalizedString("route_detail.action.start_event.hint")
        case .stopTour: return GDLocalizedString("route_detail.action.stop_event.hint")
        case .checkForUpdates: return GDLocalizedString("route_detail.action.reset.hint")
        }
    }
    
    var icon: String {
        switch action {
        case .startTour: return "play.fill"
        case .stopTour: return "pause.fill"
        case .checkForUpdates: return "arrow.triangle.2.circlepath"
        }
    }
    
    // MARK: Telemetry
    
    var telemetryEvent: String {
        switch action {
        case .startTour: return "route_action.start_event"
        case .stopTour: return "route_action.stop_event"
        case .checkForUpdates: return "route_action.reset_event"
        }
    }
}

enum GuidedTourAction: String, Action {
    
    case startTour
    case stopTour
    case checkForUpdates
    
    static func actions(for detail: TourDetail) -> [GuidedTourActionState] {
        let isDefaultBehaviorActive = AppContext.shared.eventProcessor.activeBehavior is SoundscapeBehavior
        
        if detail.isGuidanceActive {
            return [GuidedTourActionState(.stopTour)]
        } else {
            return [GuidedTourActionState(.startTour, isEnabled: isDefaultBehaviorActive), GuidedTourActionState(.checkForUpdates)]
        }
    }
}
