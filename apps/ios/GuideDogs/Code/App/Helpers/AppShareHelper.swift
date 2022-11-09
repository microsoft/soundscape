//
//  AppShareHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import UIKit

class AppShareHelper {
    
    // MARK: Properties
    
    /// We make sure to not prompt more than 3 times a year
    static let minimumTimeIntervalBetweenPrompts = TimeInterval(60*60*24*122) // 122 days
    
    static let minimumAppUsesBeforePrompt = 6
    
    static let shareURL = URL(string: "https://apps.apple.com/app/id\(AppContext.appStoreId)")!
    
    // MARK: Methods
    
    /// Show the share prompt
    /// - Returns: If the prompt has been shown
    @discardableResult
    static func promptShareIfNeeded(fromViewController viewController: UIViewController) -> Bool {
        // Make sure the user used the app for at least a few times times
        // and has not already been prompted for this version
        guard SettingsContext.shared.appUseCount >= minimumAppUsesBeforePrompt,
              LaunchActivity.lastAttemptedVersion(for: .shareApp) != AppContext.appVersion else {
                  return false
              }
        
        // Make sure to not prompt more than 3 times within a 365-day period
        if let lastPromptedDate = LaunchActivity.lastAttemptedDate(for: .shareApp) {
            guard lastPromptedDate.addingTimeInterval(minimumTimeIntervalBetweenPrompts) < Date() else {
                return false
            }
        }
        
        let alert = UIAlertController(title: GDLocalizedString("share.prompt.title"),
                                      message: GDLocalizedString("share.prompt.message"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.not_now"), style: .cancel, handler: { (_) in
            GDATelemetry.track("app.share.not_now")
        }))
        
        let shareAction = UIAlertAction(title: GDLocalizedString("share.title"), style: .default, handler: { (_) in
            share()
        })
        alert.addAction(shareAction)
        alert.preferredAction = shareAction
        
        viewController.present(alert, animated: true, completion: nil)
        
        LaunchActivity.logAttempt(.shareApp)
        
        return true
    }
    
    /// Present the share sheet to share the app
    /// - Returns: If the prompt has been shown
    @discardableResult
    static func share() -> Bool {
        guard let rootViewController = AppContext.rootViewController else {
            return false
        }
        
        let activityViewController = UIActivityViewController(activityItems: [GDLocalizedString("share.action.message"), shareURL], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { activityType, completed, _, error in
            GDATelemetry.track("app.share.completion", with: ["activityType": activityType?.rawValue ?? "none",
                                                              "completed": completed.description,
                                                              "error": error?.localizedDescription ?? "none"])
            
        }
        
        rootViewController.present(activityViewController, animated: true, completion: nil)
        
        GDATelemetry.track("app.share.shown")
        
        return true
    }
    
}
