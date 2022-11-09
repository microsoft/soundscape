//
//  LaunchActivityCoordinator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import UIKit

struct LaunchActivityCoordinator {
    
    static func coordinateActivitiesOnAppLaunch(from viewController: UIViewController) {
        for activity in LaunchActivity.allCases where attemptActivity(activity, from: viewController) {
            // Launch activity was presented to the user
            // Do not attempt remaining activities
            return
        }
    }
    
    /**
     * Attempt the handler's launch activity
     *
     * - Parameters:
     *     - activity: the launch activity
     *     - viewController: the currently presented view controller
     *
     * - Returns: true if attempt is successful, false if attempt fails or is deferred
     */
    private static func attemptActivity(_ activity: LaunchActivity, from viewController: UIViewController) -> Bool {
        switch activity {
        case .shareApp: return AppShareHelper.promptShareIfNeeded(fromViewController: viewController)
        case .reviewApp: return AppReviewHelper.promptAppReviewIfNeeded()
        }
    }
    
}
