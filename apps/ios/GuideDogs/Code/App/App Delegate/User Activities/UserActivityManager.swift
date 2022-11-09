//
//  UserActivityManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CocoaLumberjackSwift

class UserActivityManager {
    
    // MARK: Properties
    
    private let universalLinkManager = UniversalLinkManager()
    private let userActionManager = UserActionManager()
    
    // MARK: Manage User Activites
    
    func onContinueUserActivity(_ userActivity: NSUserActivity) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            return continueBrowsingWebUserActivity(userActivity)
        } else if userActivity.isUserAction {
            return continueUserActionActivity(userActivity)
        } else {
            DDLogError("NSUserActivity is not supported")
            // Notify iOS that the user activity was not handled by
            // the app
            return false
        }
    }
    
    private func continueBrowsingWebUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard let url = userActivity.webpageURL else {
            DDLogError("Webpage URL is expected for NSUserActivityTypeBrowsingWeb")
            // Notify iOS that the user activity was not handled by
            // the app
            return false
        }
        
        return universalLinkManager.onLaunchWithUniversalLink(with: url)
    }
    
    private func continueUserActionActivity(_ userActivity: NSUserActivity) -> Bool {
        guard let userAction = UserAction(userActivity: userActivity) else {
            DDLogError("NSUserActivity is expected to be a UserAction type")
            return false
        }
        
        return userActionManager.continueUserAction(userAction)
    }
    
}
