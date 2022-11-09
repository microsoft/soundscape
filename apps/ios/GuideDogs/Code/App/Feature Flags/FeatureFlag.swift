//
//  FeatureFlag.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum FeatureFlag {
    
    //
    // For each flag, add a case to `FeatureFlag`
    // Flags are enabled in feature flag configuration files
    // (`FeatureFlags-Release`, `FeatureFlags-Debug`, `FeatureFlags-AdHoc`)
    //
    
    case developerTools
    case experimentConfiguration
    
    static func isEnabled(_ feature: FeatureFlag) -> Bool {
        #if FF_DISABLE_ALL
        // All feature flags are disabled
        return false
        #elseif FF_ENABLE_ALL
        // All feature flags are enabled
        return true
        #else
        // Check the given feature flag
        switch feature {
        case .developerTools:
            #if FF_DEVELOPER_TOOLS
            return true
            #else
            return false
            #endif
        case .experimentConfiguration:
            #if FF_EXPERIMENT_CONFIG
            return true
            #else
            return false
            #endif
        }
        #endif
    }
    
}
