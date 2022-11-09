//
//  LocationAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum LocationAction {
    
    case save(isEnabled: Bool)
    case edit
    case beacon
    case preview
    case share(isEnabled: Bool)
    
    var isEnabled: Bool {
        switch self {
        case .save(let isEnabled): return isEnabled
        case .share(let isEnabled): return isEnabled
        case .beacon, .preview, .edit:
            if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance {
                return false
            } else {
                return true
            }
        }
    }
    
    static func actions(for detail: LocationDetail) -> [LocationAction] {
        if detail.isMarker {
            return [.beacon, .edit, .preview, .share(isEnabled: true)]
        } else {
            // If the location does not have a backup coordinate
            // disable the save and share actions
            let isEnabled = detail.source.isCachingEnabled
            
            return [.beacon, .save(isEnabled: isEnabled), .preview, .share(isEnabled: isEnabled)]
        }
    }
    
    // MARK: Accessibility Custom Actions
    
    static func accessibilityCustomActions(for entity: POI, callback: @escaping (LocationAction, POI) -> Void) -> [UIAccessibilityCustomAction] {
        let detail = LocationDetail(entity: entity)
        
        return actions(for: detail).reversed().compactMap({ (action) in
            guard action.isEnabled else {
                return nil
            }
            
            let name = action.text
            
            return UIAccessibilityCustomAction(name: name) { (_) -> Bool in
                callback(action, entity)
                return true
            }
        })
    }
    
    // MARK: Localization
    
    var text: String {
        switch self {
        case .save: return GDLocalizedString("universal_links.alert.action.marker")
        case .edit: return GDLocalizedString("markers.edit_screen.title.edit")
        case .beacon: return GDLocalizedString("location_detail.action.beacon")
        case .preview: return GDLocalizedString("preview.title")
        case .share: return GDLocalizedString("share.title")
        }
    }
    
    var accessibilityHint: String? {
        switch self {
        case .save(let isEnabled): return isEnabled ? GDLocalizedString("location_detail.action.save.hint") : GDLocalizedString("location_detail.disabled.save")
        case .edit: return GDLocalizedString("location_detail.action.edit.hint")
        case .beacon: return isEnabled ? GDLocalizedString("location_detail.action.beacon.hint") : GDLocalizedString("location_detail.action.beacon.hint.disabled")
        case .preview: return isEnabled ? GDLocalizedString("location_detail.action.preview.hint") : GDLocalizedString("location_detail.action.preview.hint.disabled")
        case .share(let isEnabled): return isEnabled ? GDLocalizedString("location_detail.action.share.hint") : GDLocalizedString("location_detail.disabled.share")
        }
    }
    
    var accessibilityIdentifier: String? {
        switch self {
        case .save: return GDLocalizationUnnecessary("action.save")
        case .edit: return GDLocalizationUnnecessary("action.edit")
        case .beacon: return GDLocalizationUnnecessary("action.beacon")
        case .preview: return GDLocalizationUnnecessary("action.preview")
        case .share: return GDLocalizationUnnecessary("action.share")
        }
    }
    
    var image: UIImage? {
        switch self {
        case .save: return UIImage(named: "AddMarker_iconW")
        case .edit: return UIImage(named: "EditMarker_icon")
        case .beacon: return UIImage(named: "Location_iconW")
        case .preview: return UIImage(named: "Preview_locationW")
        case .share: return UIImage(named: "Share_iconW")
        }
    }
    
    // MARK: Telemetry
    
    var telemetryEvent: String {
        switch self {
        case .save: return "location_action.save"
        case .edit: return "location_action.edit"
        case .beacon: return "location_action.beacon"
        case .preview: return "location_action.preview"
        case .share: return "location_action.share"
        }
    }
}
