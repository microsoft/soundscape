//
//  AppReviewHelper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import StoreKit

class AppReviewHelper {
    
    // MARK: Properties
    
    /// Apple notes that prompting review with the `SKStoreReviewController` framework will
    /// only be displayed to a user a maximum of 3 times within a 365-day period.
    static let minimumTimeIntervalBetweenPrompts = TimeInterval(60*60*24*122) // 122 days
    
    static let minimumAppUsesBeforePrompt = 3
    
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(AppContext.appStoreId)?action=write-review")!
    
    // MARK: Methods
    
    /// Show the in-app review prompt.
    /// - Returns: If the prompt has been shown
    @discardableResult
    static func promptAppReviewIfNeeded() -> Bool {
        // Make sure the user used the app for at least a few times times
        // and has not already been prompted for this version
        guard SettingsContext.shared.appUseCount >= minimumAppUsesBeforePrompt,
              LaunchActivity.lastAttemptedVersion(for: .reviewApp) != AppContext.appVersion else {
                  return false
              }
        
        // Make sure to not prompt more than 3 times within a 365-day period
        if let lastPromptedDate = LaunchActivity.lastAttemptedDate(for: .reviewApp) {
            guard lastPromptedDate.addingTimeInterval(minimumTimeIntervalBetweenPrompts) < Date() else {
                return false
            }
        }
        
        let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first
        
        guard let scene = windowScene else {
            return false
        }
        
        SKStoreReviewController.requestReview(in: scene)
        
        LaunchActivity.logAttempt(.reviewApp)
        
        GDATelemetry.track("app.rate.prompt_rate")
        
        return true
    }
    
    /// Deep-link to the App Store product page to write a review
    /// - Returns: If the prompt has been shown
    @discardableResult
    static func showWriteReviewPage() -> Bool {
        guard UIApplication.shared.canOpenURL(writeReviewURL) else {
            return false
        }
        
        UIApplication.shared.open(writeReviewURL)
        
        GDATelemetry.track("app.rate.write_review")
        
        return true
    }
    
}
