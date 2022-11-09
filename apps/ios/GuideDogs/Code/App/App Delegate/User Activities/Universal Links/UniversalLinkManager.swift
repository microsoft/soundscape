//
//  UniversalLinkManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class UniversalLinkManager {
    
    // MARK: Properties
    
    private var pendingLinkComponents: [UniversalLinkComponents] = []
    private var homeViewControllerDidLoad = false
    private var queue = DispatchQueue(label: "com.company.appname.universallinkmanager")
    // Handlers
    private let recreationalActivityLinkHandler = RecreationalActivityLinkHandler()
    private let shareMarkerLinkHandler = ShareMarkerLinkHandler()
    
    // MARK: Initialization
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onHomeViewControllerDidLoad), name: Notification.Name.homeViewControllerDidLoad, object: nil)
    }
    
    // MARK: Notifications
    
    @objc
    func onHomeViewControllerDidLoad() {
        queue.async {
            self.homeViewControllerDidLoad = true
            
            for components in self.pendingLinkComponents {
                self.launchWithUniversalLink(with: components)
            }
            
            self.pendingLinkComponents = []
        }
    }
    
    // MARK: Manage Universal Links
    
    func onLaunchWithUniversalLink(with url: URL) -> Bool {
        guard let components = UniversalLinkComponents(url: url) else {
            // Failed to parse URL for universal link
            GDATelemetry.track("deeplink.unsupported")
            // Notify iOS that the link was not handled by
            // the app
            return false
        }
        
        if homeViewControllerDidLoad {
            queue.async {
                self.launchWithUniversalLink(with: components)
            }
        } else {
            // App is not initialized (e.g. first launch experience
            // is in progress) Add to array of universal links
            // pending action
            queue.async {
                self.pendingLinkComponents.append(components)
            }
        }
        
        // Notify iOS that link will be handled by the
        // app
        //
        // If the app fails to act on the link, the app is
        // now responsible for displaying the appropriate
        // failure notifications
        return true
    }
    
    private func launchWithUniversalLink(with components: UniversalLinkComponents) {
        let handler: UniversalLinkHandler
        
        let version = components.pathComponents.version
        let path = components.pathComponents.path
        
        switch path {
        case .experience:
            GDATelemetry.track("deeplink.experiences")
            handler = recreationalActivityLinkHandler
        case .shareMarker:
            GDATelemetry.track("deeplink.share_marker")
            handler = shareMarkerLinkHandler
        }
        
        // Dispatch to the appropriate universal link
        // handler
        handler.handleUniversalLink(with: components.queryItems, version: version)
    }
    
}

extension UniversalLinkManager {
    
    static func shareMarker(_ marker: ReferenceEntity) -> URL? {
        guard let parameters = MarkerParameters(marker: marker) else {
            return nil
        }
        
        return UniversalLinkComponents(path: .shareMarker, parameters: parameters).url
    }
    
    static func shareEntity(_ entity: POI) -> URL? {
        guard let parameters = MarkerParameters(entity: entity) else {
            return nil
        }
        
        return UniversalLinkComponents(path: .shareMarker, parameters: parameters).url
    }
    
    static func shareLocation(_ detail: LocationDetail) -> URL? {
        guard let parameters = MarkerParameters(location: detail) else {
            return nil
        }
        
        return UniversalLinkComponents(path: .shareMarker, parameters: parameters).url
    }
    
    static func shareLocation(name: String, latitude: Double, longitude: Double) -> URL? {
        let parameters = MarkerParameters(name: name, latitude: latitude, longitude: longitude)
        return UniversalLinkComponents(path: .shareMarker, parameters: parameters).url
    }
    
}
