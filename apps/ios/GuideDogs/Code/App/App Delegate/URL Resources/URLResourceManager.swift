//
//  URLResourceManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

/*
 Delegates URL resources to the appropriate handler after the resource is opened by the app.
 
 Supported resource types are defined in the Info.plist (`Imported Type Identifiers` and `Exported Type Identifiers`) and the expected identifier is additionally defined in `URLResourceIdentifier`
 */
class URLResourceManager {
    
    private struct URLResource {
        let identifier: URLResourceIdentifier
        let url: URL
    }
    
    // MARK: Properties
    
    private var listeners: [AnyCancellable] = []
    private var pendingURLResources: [URLResource] = []
    private var homeViewControllerDidLoad = false
    private var queue = DispatchQueue(label: "com.company.appname.urlresourcemanager")
    // Handlers
    private let gpxHandler = GPXResourceHandler()
    private let routeHandler = RouteResourceHandler()
    
    // MARK: Initialization
    
    init() {
        listeners.append(NotificationCenter.default.publisher(for: .homeViewControllerDidLoad)
                            .receive(on: RunLoop.main)
                            .sink(receiveValue: { [weak self] _ in
                                guard let `self` = self else {
                                    return
                                }
                                
                                self.queue.async {
                                    self.homeViewControllerDidLoad = true
                                    
                                    for resource in self.pendingURLResources {
                                        self.openResource(resource)
                                    }
                                    
                                    self.pendingURLResources = []
                                }
                            }))
    }
    
    // MARK: Manage URL Resources
    
    /*
     Delegates URL resources to the appropriate handler.
     
     Returns TRUE if the resource type is supported by the app and has a corresponding handler
     Returns FALSE if the resource type is not supported
     */
    func onOpenResource(from url: URL) -> Bool {
        guard let iRawValue = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            return false
        }
        
        guard let identifier = URLResourceIdentifier(rawValue: iRawValue) else {
            return false
        }
        
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let resource = URLResource(identifier: identifier, url: url)
            
            if self.homeViewControllerDidLoad {
                self.openResource(resource)
            } else {
                self.pendingURLResources.append(resource)
            }
        }
        
        return true
    }
    
    private func openResource(_ resource: URLResource) {
        let handler: URLResourceHandler
        
        switch resource.identifier {
        case .gpx: handler = gpxHandler
        case .route: handler = routeHandler
        }
        
        handler.handleURLResource(with: resource.url)
    }
    
    static func removeURLResource(at url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            GDLogURLResourceError("Failed to remove file for URL resource")
        }
    }
    
}

extension URLResourceManager {
    
    static func shareRoute(_ route: Route) -> URL? {
        return RouteParameters.encodeAndWriteToTemporaryFile(from: route, context: .share)
    }
    
}
