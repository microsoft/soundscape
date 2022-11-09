//
//  GPXResourceHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CocoaLumberjackSwift

extension Notification.Name {
    static let didImportGPXResource = Notification.Name("GDADidImportGPXResource")
}

/*
 URL resource handler for the GPX document type.
 
 Importing GPX resources is subject to the `.developerTools` feature flag
 */
class GPXResourceHandler: URLResourceHandler {
    
    // MARK: Notification Keys
    
    struct Keys {
        static let filename = "Filename"
        static let error = "Error"
    }
    
    // MARK: `URLResourceHandler`
    
    /*
     Tries to import the GPX resource from the given URL
     
     If import succeeds, the GPX file is saved to the device and an alert is displayed to the user.
     If import fails, an alert is displayed to the user.
     
     Importing GPX resources is subject to the `.developerTools` feature flag
     */
    func handleURLResource(with url: URL) {
        guard FeatureFlag.isEnabled(.developerTools) else {
            // Importing a GPX file is an internal developer tool that is only
            // available when the corresponding feature flag is enabled
            //
            // no-op
            DDLogError("Developer tools are not enabled in this build")
            return
        }
        
        do {
            try GPXFileManager.import(url: url)
            postNotification(url: url, error: nil)
        } catch {
            DDLogError("Could not import GPX file with error: \(error)")
            postNotification(url: url, error: error)
        }
    }
    
    private func postNotification(url: URL, error: Error?) {
        var userInfo: [String: Any] = [Keys.filename: url.lastPathComponent]
           
        if let error = error {
            // Add error, if provided
            userInfo[Keys.error] = error
        }
        
        // Notify `ImportURLResourceAlertObserver`
        NotificationCenter.default.post(name: Notification.Name.didImportGPXResource,
                                        object: self,
                                        userInfo: userInfo)
    }
    
}
