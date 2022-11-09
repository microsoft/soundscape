//
//  RouteDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

class RouteDetail: RouteDetailProtocol {
    
    struct DesignData {
        var id: String
        var name: String?
        var description: String?
        var waypoints: [LocationDetail]
    }
    
    enum Source {
        // `Route` has been added to the Realm database
        case database(id: String)
        // `Route` has not been added to the Realm database
        // (e.g., on import via sharing activity)
        case cache(route: Route)
        case trailActivity(content: AuthoredActivityContent)
    }
    
    // MARK: Properties
    
    let source: Source
    private(set) var name: String?
    private(set) var description: String?
    private(set) var waypoints: [LocationDetail] = []
    private let designData: DesignData?
    private var listeners: [AnyCancellable] = []
    
    var guidance: RouteGuidance? {
        guard let routeGuidance = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
            return nil
        }
        
        guard routeGuidance.content.id == id else {
            return nil
        }
        
        return routeGuidance
    }
    
    var isGuidanceActive: Bool {
        return guidance != nil
    }
    
    var id: String {
        if let designData = designData {
            return designData.id
        }
        
        switch source {
        case .database(let id):
            return id
            
        case .cache(let route):
            return route.id
            
        case .trailActivity(let activity):
            return activity.id
        }
    }
    
    var displayName: String {
        if let name = name, name.isEmpty == false {
            return name
        }
        
        return GDLocalizedString("route_detail.name.default")
    }
    
    var isExpiredTrailActivity: Bool {
        if case .trailActivity(let activity) = source, activity.isExpired {
            return true
        }
        
        return false
    }
    
    // MARK: Initialization
    
    init(source: Source) {
        self.source = source
        self.designData = nil
        
        // Initialize route properties
        setRouteProperties()
        
        if case .database(let id) = source {
            listeners.append(NotificationCenter.default.publisher(for: .routeUpdated)
                                .receive(on: DispatchQueue.main)
                                .sink(receiveValue: { [weak self] notification in
                guard let `self` = self else {
                    return
                }
                
                guard let newId = notification.userInfo?[Route.Keys.id] as? String else {
                    return
                }
                
                guard id == newId else {
                    return
                }
                
                // Update route properties
                self.setRouteProperties()
            }))
        }
    }
    
    init(source: Source, designData: DesignData) {
        self.source = source
        self.designData = designData
        
        // Initialize route properties
        setRouteProperties()
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
    // MARK: Route Properties
    
    private func setRouteProperties() {
        if let designData = designData {
            name = designData.name
            description = designData.description
            waypoints = designData.waypoints
        }
        
        switch source {
        case .database(let id):
            guard let route = Route.object(forPrimaryKey: id) else {
                return
            }
            
            name = route.name
            description = route.routeDescription
            waypoints = route.waypoints.ordered.asLocationDetail
            
        case .cache(let route):
            name = route.name
            description = route.routeDescription
            waypoints = route.waypoints.ordered.asLocationDetail
            
        case .trailActivity(let activity):
            name = activity.name
            description = activity.desc
            waypoints = activity.waypoints.map { wpt -> LocationDetail in
                let detail = ImportedLocationDetail(nickname: wpt.name,
                                                    annotation: wpt.description,
                                                    departure: wpt.departureCallout,
                                                    arrival: wpt.arrivalCallout)
                
                return LocationDetail(location: CLLocation(wpt.coordinate),
                                      imported: detail,
                                      telemetryContext: "route_detail")
            }
        }
    }
    
}
