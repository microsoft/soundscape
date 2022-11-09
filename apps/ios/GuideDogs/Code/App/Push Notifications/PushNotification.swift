//
//  PushNotification.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// An object that encapsulates a push notification payload
/// Reference and other possible values:
/// https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification
struct PushNotification {
    
    // MARK: Types
    
    /// Represents the arrivel method used (foreground, background or app launch)
    enum ArrivalContext: String {
        /// Received when app is in foreground or background
        case `default`
        /// Received when app launched
        case launch
    }
    
    /// Represents the origin method used (remote, local)
    enum OriginContext: String {
        case remote
        case local
    }
    
    /// APNs notifications return as dictionaries
    typealias Payload = [AnyHashable: Any]
    
    // MARK: Constants
    
    struct Keys {
        /// Identifier for a local push notification
        static let localIdentifier = "GDALocalIdentifier"
        /// Internal use when scheduling local notification
        static let OriginContext = "GDAOriginContext"
        /// Should be set if the app should process a url (such as show a webview)
        static let Url = "url"
    }
    
    // MARK: Properties
    
    /// Original payload/userInfo
    let payload: Payload
    
    // Keys from the "aps" dictionary
    let title: String?
    let subtitle: String?
    let body: String?
    
    // Custom keys
    let localIdentifier: String?
    let arrivalContext: ArrivalContext
    let originContext: OriginContext
    let userAction: UserAction?
    let url: String?
    
    // MARK: Initialization
    
    init(payload: Payload, arrivalContext: ArrivalContext = .default) {
        self.payload = payload
        
        if let aps = payload["aps"] as? [String: Any] {
            // Apple's definition of the "alert" object:
            // "The information for displaying an alert. A dictionary is recommended.
            // If you specify a string, the alert displays your string as the body text."
            if let alert = aps["alert"] as? [String: Any] {
                title = alert["title"] as? String
                subtitle = alert["subtitle"] as? String
                body = alert["body"] as? String
            } else if let alert = aps["alert"] as? String {
                title = nil
                subtitle = nil
                body = alert
            } else {
                title = nil
                subtitle = nil
                body = nil
            }
        } else {
            title = nil
            subtitle = nil
            body = nil
        }
        
        localIdentifier = payload[Keys.localIdentifier] as? String
        
        self.arrivalContext = arrivalContext
        
        originContext = {
            guard let originContextString = payload[Keys.OriginContext] as? String,
                  let originContext = OriginContext(rawValue: originContextString) else { return .remote }
            return originContext
        }()
        
        userAction = {
            guard let userActionIdentifier = payload[UserActionManager.Keys.userAction] as? String,
                  let userAction = UserAction(identifier: userActionIdentifier) else { return nil }
            return userAction
        }()
        
        url = payload[Keys.Url] as? String
    }
    
}
