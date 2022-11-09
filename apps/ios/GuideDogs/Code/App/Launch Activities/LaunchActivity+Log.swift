//
//  LaunchActivity+Log.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension LaunchActivity {
    
    // MARK: Log Data
    
    static func lastAttemptedVersion(for activity: LaunchActivity) -> String? {
        return UserDefaults.standard.string(forKey: activity.keys.version)
    }
    
    static func lastAttemptedDate(for activity: LaunchActivity) -> Date? {
        return UserDefaults.standard.object(forKey: activity.keys.date) as? Date
    }
    
    static func didLastAttemptComplete(for activity: LaunchActivity) -> Bool {
        UserDefaults.standard.bool(forKey: activity.keys.didComplete)
    }
    
    // MARK: Log
    
    static func logAttempt(_ activity: LaunchActivity, didComplete: Bool = true) {
        UserDefaults.standard.set(AppContext.appVersion, forKey: activity.keys.version)
        UserDefaults.standard.set(Date(), forKey: activity.keys.date)
        UserDefaults.standard.set(didComplete, forKey: activity.keys.didComplete)
    }
    
}

private extension LaunchActivity {
    
    // MARK: Keys
    
    var keys: Keys {
        return Keys(activity: self)
    }
    
    struct Keys {
        
        let activity: LaunchActivity
        
        private var prefixKey: String {
            switch activity {
            case .shareApp: return "GDAAppShare"
            case .reviewApp: return "GDAAppReview"
            }
        }
        
        var version: String {
            switch activity {
            case .reviewApp:
                // User existing key for `.reviewApp`
                return prefixKey + "LastVersionPrompted"
            default:
                return prefixKey + "LastPromptedVersion"
            }
        }
        
        var date: String {
            return prefixKey + "LastPromptedDate"
        }
        
        var didComplete: String {
            return prefixKey + "LastDidComplete"
        }
        
    }
    
}
