//
//  RecreationalActivityLinkHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CocoaLumberjackSwift

extension Notification.Name {
    static let processedActivityDeepLink = Notification.Name("ProcessedActivityDeepLink")
    static let activityDownloadDidFail = Notification.Name("ActivityDownloadDidFail")
}

class RecreationalActivityLinkHandler: UniversalLinkHandler {
    
    // MARK: Parameters
    
    private struct Parameters {
        let id: String
    }
    
    // MARK: `UniversalLinkHandler`
    
    func handleUniversalLink(with queryItems: [URLQueryItem]?, version: UniversalLinkVersion) {
        guard let parameters = parseQueryItems(queryItems) else {
            // Failed to parse the expected parameters
            DispatchQueue.main.async { [weak self] in
                NotificationCenter.default.post(name: Notification.Name.activityDownloadDidFail, object: self)
            }
            return
        }

        if AuthoredActivityLoader.shared.activityExists(parameters.id) {
            // If we have already downloaded the recreational activity,
            // transition to the UI to the list of downloaded activities
            DispatchQueue.main.async { [weak self] in
                NotificationCenter.default.post(name: Notification.Name.processedActivityDeepLink, object: self)
            }
        } else {
            // Download the recreational activity
            downloadRecreationalActivity(with: parameters.id, version: version)
        }
    }
    
    private func parseQueryItems(_ queryItems: [URLQueryItem]?) -> Parameters? {
        guard let queryItems = queryItems else {
            DDLogError("Recreational activity universal link is invalid")
            return nil
        }
        
        guard let id = queryItems.first(where: { $0.name == "id" })?.value else {
            DDLogError("Recreational activity universal link is invalid - `id` is required")
            return nil
        }
        
        return Parameters(id: id)
    }
    
    // MARK: Handle Recreational Activities
    
    @MainActor
    private func showRecreationalActivity() {
        NotificationCenter.default.post(name: Notification.Name.processedActivityDeepLink, object: self)
    }
    
    @MainActor
    private func didFailToDownloadActivity() {
        NotificationCenter.default.post(name: Notification.Name.activityDownloadDidFail, object: self)
    }
    
    private func downloadRecreationalActivity(with id: String, version: UniversalLinkVersion) {
        Task {
            do {
                try await AuthoredActivityLoader.shared.add(id, linkVersion: version)
                await showRecreationalActivity()
            } catch {
                await didFailToDownloadActivity()
            }
        }
    }
    
}
