//
//  DateComponentsFormatter+Extension.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension DateComponentsFormatter {
    
    static var timeElapsedFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute]
        formatter.maximumUnitCount = 0
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter
    }
    
    static var accessibilityTimeElapsedFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .full
        
        return formatter
    }
    
}
