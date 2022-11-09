//
//  Heading+Order.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Heading {
    
    private struct Order {
        
        static let collection: [HeadingType] = [.course, .user, .device]
        static let presentation: [HeadingType] = [.user, .course, .device]
        
    }
    
    static func defaultCollection(course: HeadingValue?, deviceHeading: HeadingValue?, userHeading: HeadingValue?, geolocationManager: GeolocationManagerProtocol? = nil) -> Heading {
        let types = Order.collection
        return Heading(orderedBy: types, course: course, deviceHeading: deviceHeading, userHeading: userHeading, geolocationManager: geolocationManager)
    }
    
    static func defaultPresentation(course: HeadingValue?, deviceHeading: HeadingValue?, userHeading: HeadingValue?, geolocationManager: GeolocationManagerProtocol? = nil) -> Heading {
        let types = Order.presentation
        return Heading(orderedBy: types, course: course, deviceHeading: deviceHeading, userHeading: userHeading, geolocationManager: geolocationManager)
    }
    
}
