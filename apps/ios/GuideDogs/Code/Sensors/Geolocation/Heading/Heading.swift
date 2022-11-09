//
//  Heading.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol HeadingNotifier {
    var value: Double? { get }
    var accuracy: Double? { get }
    func onHeadingDidUpdate(_ completionHandler: (((_ heading: HeadingValue?) -> Void)?))
}

class Heading: HeadingNotifier {
    
    // MARK: Properties
    
    static let defaultValue: Double = 0.0
    
    private var course: HeadingValue?
    private var deviceHeading: HeadingValue?
    private var userHeading: HeadingValue?
    private let types: [HeadingType]
    private var onHeadingDidUpdate: ((_ heading: HeadingValue?) -> Void)?
    
    private var heading: (headingValue: HeadingValue, headingType: HeadingType)? {
        for type in types {
            switch type {
            case .user: if let userHeading = userHeading { return (userHeading, .user) }
            case .course: if let course = course { return (course, .course) }
            case .device: if let deviceHeading = deviceHeading { return (deviceHeading, .device) }
            }
        }
        
        // Heading is invalid
        return nil
    }
    
    var value: Double? {
        return heading?.headingValue.value
    }
    
    var accuracy: Double? {
        return heading?.headingValue.accuracy
    }
    
    var isCourse: Bool {
        guard let type = heading?.headingType else {
            // Heading is invalid
            // Use `false` as default value
            return false
        }
        
        switch type {
        case .user: return false
        case .course: return true
        case .device: return false
        }
    }
    
    // MARK: Initialization
    
    init(orderedBy types: [HeadingType],
         course: HeadingValue?,
         deviceHeading: HeadingValue?,
         userHeading: HeadingValue?,
         geolocationManager: GeolocationManagerProtocol? = nil) {
        self.types = types
        self.course = course
        self.deviceHeading = deviceHeading
        self.userHeading = userHeading
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onHeadingTypeDidChange(_:)),
                                               name: Notification.Name.headingTypeDidUpdate,
                                               object: geolocationManager)
    }
    
    /// Copy constructor
    ///
    /// - Parameter from: Another Heading object to copy configuration information from
    convenience init(from: Heading, geolocationManager: GeolocationManagerProtocol? = nil) {
        self.init(orderedBy: from.types,
                  course: from.course,
                  deviceHeading: from.deviceHeading,
                  userHeading: from.userHeading,
                  geolocationManager: geolocationManager)
    }
    
    // MARK: Notifications
    
    func onHeadingDidUpdate(_ completionHandler: (((_ heading: HeadingValue?) -> Void)?)) {
        self.onHeadingDidUpdate = completionHandler
    }
    
    @objc private func onHeadingTypeDidChange(_ notification: Notification) {
        guard let headingType = notification.userInfo?[GeolocationManager.Key.type] as? HeadingType else {
            return
        }
        
        var headingValue: HeadingValue?
        
        if let value = notification.userInfo?[GeolocationManager.Key.value] as? Double {
            let accuracy = notification.userInfo?[GeolocationManager.Key.accuracy] as? Double
            headingValue = HeadingValue(value, accuracy)
        }
        
        // Save old value for calculated `heading`
        let oldValue = self.heading?.headingValue
        
        switch headingType {
        case .course: course = headingValue
        case .device: deviceHeading = headingValue
        case .user: userHeading = headingValue
        }
        
        // Calculate new value for `heading`
        let newValue = self.heading?.headingValue
        
        guard oldValue != newValue else {
            return
        }
        
        onHeadingDidUpdate?(newValue)
    }
    
}
