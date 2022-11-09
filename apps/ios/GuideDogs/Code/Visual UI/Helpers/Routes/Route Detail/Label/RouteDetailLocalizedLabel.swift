//
//  RouteDetailLocalizedLabel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct RouteDetailLocalizedLabel {
    
    // MARK: Properties
    
    let detail: RouteDetail
    
    private var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute]
        formatter.maximumUnitCount = 0
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
    
    private var accessibilityFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .full
        return formatter
    }
    
    // MARK: `LocalizedLabel`
    
    var time: LocalizedLabel? {
        guard case .trailActivity = detail.source else {
            return nil
        }
        
        var timeElapsed: TimeInterval?
        
        if let route = detail.guidance {
            // Route is active
            timeElapsed = route.runningTime
        } else if let state = RouteGuidanceState.load(id: detail.id) {
            // Route is not active
            timeElapsed = state.totalTime
        }
        
        guard let timeElapsed = timeElapsed else {
            return nil
        }
        
        guard let timeElapsedStr = formatter.string(from: timeElapsed) else {
            return nil
        }
        
        guard let timeElapsedAccessibilityStr = accessibilityFormatter.string(from: timeElapsed) else {
            return nil
        }
        
        let text = GDLocalizedString("route.title.time", timeElapsedStr)
        let accessibilityText = GDLocalizedString("route.title.time", timeElapsedAccessibilityStr)
        
        return LocalizedLabel(text: text, accessibilityText: accessibilityText)
    }
    
}

extension RouteDetail {
    
    var labels: RouteDetailLocalizedLabel {
        return RouteDetailLocalizedLabel(detail: self)
    }
    
}
