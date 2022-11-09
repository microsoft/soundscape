//
//  ShareMarkerLinkHandler.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let didImportMarker = Notification.Name("DidImportMarker")
    static let didFailToImportMarker = Notification.Name("DidFailToImportMarker")
}

class ShareMarkerLinkHandler: UniversalLinkHandler {
    
    // MARK: Keys
     
    struct Keys {
        static let location = "Location"
        static let nickname = "Nickname"
        static let annotation = "Annotation"
    }
     
    // MARK: `UniversalLinkHandler`
     
    func handleUniversalLink(with queryItems: [URLQueryItem]?, version: UniversalLinkVersion) {
        guard let queryItems = queryItems else {
            GDLogUniversalLinkError("Universal link is invalid - `queryItems` is nil")
            self.didFailToImportMarker()
            return
        }
        
        guard let markerParameters = MarkerParameters(queryItems: queryItems) else {
            GDLogUniversalLinkError("Universal link is invalid - Failed to parse a `MarkerParameters` object from query items")
            self.didFailToImportMarker()
            return
        }
        
        handle(markerParameters: markerParameters)
    }
    
    private func handle(markerParameters: MarkerParameters) {
        // Fetch the underlying entity
        //
        // For OSM entities, add or update the entity in the cache
        markerParameters.location.fetchEntity { [weak self] (result) in
            guard let `self` = self else { return }

            switch result {
            case .success(let entity):
                self.importMarker(markerParameters: markerParameters, location: entity)
            case .failure(let error):
                GDLogUniversalLinkError("Error loading underlying entity: \(error)")
                self.didFailToImportMarker()
            }
        }
    }
    
    // MARK: Notifications
     
    private func importMarker(markerParameters: MarkerParameters, location: POI) {
        var userInfo: [String: Any] = [Keys.location: location]

        if let nickname = markerParameters.nickname {
            userInfo[Keys.nickname] = nickname
        }

        if let annotation = markerParameters.annotation {
            userInfo[Keys.annotation] = annotation
        }

        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: Notification.Name.didImportMarker,
                                            object: self,
                                            userInfo: userInfo)
        }
    }
     
    private func didFailToImportMarker() {
        let name = Notification.Name.didFailToImportMarker
        
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: name, object: self)
        }
    }
    
}
