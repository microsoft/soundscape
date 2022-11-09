//
//  TourDetail.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation
import Combine

class TourDetail: RouteDetailProtocol {
    
    // MARK: Properties
    
    let event: AuthoredActivityContent
    
    private(set) var name: String?
    private(set) var description: String?
    private(set) var waypoints: [LocationDetail] = []
    private(set) var pois: [LocationDetail] = []
    
    private var listeners: [AnyCancellable] = []
    
    var guidance: GuidedTour? {
        guard let guide = AppContext.shared.eventProcessor.activeBehavior as? GuidedTour else {
            return nil
        }
        
        guard guide.content.id == id else {
            return nil
        }
        
        return guide
    }
    
    var isGuidanceActive: Bool {
        return guidance != nil
    }
    
    var id: String {
        return event.id
    }
    
    var displayName: String {
        if let name = name, name.isEmpty == false {
            return name
        }
        
        return GDLocalizedString("route_detail.name.default")
    }
    
    // MARK: Initialization
    
    init(content: AuthoredActivityContent) {
        self.event = content
        
        // Initialize route properties
        setRouteProperties()
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
    // MARK: Route Properties
    
    private func setRouteProperties() {
        name = event.name
        description = event.desc
        waypoints = event.waypoints.map { wpt -> LocationDetail in
            let detail = ImportedLocationDetail(nickname: wpt.name,
                                                annotation: wpt.description,
                                                departure: wpt.departureCallout,
                                                arrival: wpt.arrivalCallout,
                                                images: wpt.images,
                                                audio: wpt.audioClips)
            
            return LocationDetail(location: CLLocation(wpt.coordinate),
                                  imported: detail,
                                  telemetryContext: "tour_detail")
        }
    }
    
}
