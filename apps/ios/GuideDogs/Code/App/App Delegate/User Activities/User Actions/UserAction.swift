//
//  UserAction.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Used with `NSUserActivity` to continue user activities
enum UserAction: String, CaseIterable {
    case myLocation = "my-location"
    case aroundMe = "around-me"
    case aheadOfMe = "ahead-of-me"
    case nearbyMarkers = "nearby-markers"
    case search = "search"
    case saveMarker = "save-marker"
    case streetPreview = "street-preview"
    // If adding cases here, make sure to also add them in `info.plist` under `NSUserActivityTypes`
    
    // MARK: Static
    
    private static let identifierPrefix = "\(Bundle.main.bundleIdentifier!).activity"
    
    // MARK: Properties
    
    var identifier: String {
        return UserAction.identifierPrefix + "." + self.rawValue
    }
    
    var title: String {
        switch self {
        case .myLocation:
            return GDLocalizedString("user_activity.my_location.title")
        case .aroundMe:
            return GDLocalizedString("user_activity.around_me.title")
        case .aheadOfMe:
            return GDLocalizedString("user_activity.ahead_of_me.title")
        case .nearbyMarkers:
            return GDLocalizedString("user_activity.nearby_markers.title")
        case .search:
            return GDLocalizedString("user_activity.search.title")
        case .saveMarker:
            return GDLocalizedString("user_activity.save_marker.title")
        case .streetPreview:
            return GDLocalizedString("user_activity.street_preview.title")
        }
    }
    
    var suggestedInvocationPhrase: String {
        return title
    }
    
    var keywords: Set<String> {
        switch self {
        case .myLocation:
            return [GDLocalizedString("ui.action_button.my_location"), GDLocalizedString("location")]
        case .aroundMe:
            return [GDLocalizedString("ui.action_button.around_me")]
        case .aheadOfMe:
            return [GDLocalizedString("ui.action_button.ahead_of_me")]
        case .nearbyMarkers:
            return [GDLocalizedString("ui.action_button.nearby_markers")]
        case .search:
            return [GDLocalizedString("preview.search.label")]
        case .saveMarker:
            return [GDLocalizedString("markers.generic_name")]
        case .streetPreview:
            return [GDLocalizedString("voice.action.preview")]
        }
    }
    
    // MARK: Initialization
    
    init?(identifier: String) {
        guard let userAction = UserAction.allCases.first(where: { $0.identifier == identifier }) else { return nil }
        self = userAction
    }
    
    init?(userActivity: NSUserActivity) {
        self.init(identifier: userActivity.activityType)
    }
    
}

extension NSUserActivity {
    
    convenience init(userAction: UserAction) {
        self.init(activityType: userAction.identifier)
        
        persistentIdentifier = userAction.identifier
        
        // The following properties enable the activity to be indexed in Search.
        isEligibleForPublicIndexing = true
        isEligibleForSearch = true
        title = userAction.title
        keywords = userAction.keywords
        
        // The following properties enable the activity to be used as a shortcut with Siri.
        isEligibleForPrediction = true
        suggestedInvocationPhrase = userAction.suggestedInvocationPhrase
    }
    
    var isUserAction: Bool {
        return UserAction.allCases.contains(where: { $0.identifier == self.activityType })
    }
    
}
