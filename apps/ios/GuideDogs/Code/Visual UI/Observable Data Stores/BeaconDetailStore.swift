//
//  BeaconStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

class BeaconDetailStore: ObservableObject {
    
    // MARK: Properties
    
    @Published var beacon: BeaconDetail?
    
    @Published var isRouteTransitioning: Bool = false
    
    private var listeners: [AnyCancellable] = []
    
    // MARK: Initialization
    
    convenience init() {
        let manager = AppContext.shared.spatialDataContext.destinationManager
        
        if let behavior = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance {
            let beacon = BeaconDetail(from: behavior, isAudioEnabled: manager.isAudioEnabled)
            
            // Active audio beacon is following a route
            self.init(beacon: beacon)
        } else if let key = manager.destinationKey, let beacon = SpatialDataCache.referenceEntityByKey(key) {
            let beacon = BeaconDetail(locationDetail: LocationDetail(marker: beacon), isAudioEnabled: manager.isAudioEnabled)
            
            // Active audio beacon is set on a location
            self.init(beacon: beacon)
        } else {
            // There is no active audio beacon
            self.init(beacon: nil)
        }
    }
    
    init(beacon: BeaconDetail?) {
        self.beacon = beacon
        
        // Audio beacon is muted or unmuted
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.destinationAudioChanged).sink { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard let userInfo = notification.userInfo as? [String: Any] else {
                return
            }
            
            guard let isAudioEnabled = userInfo[DestinationManager.Keys.isAudioEnabled] as? Bool else {
                return
            }
            
            // Update `isAudioEnabled`
            self.beacon?.isAudioEnabled = isAudioEnabled
        })
        
        // Audio beacon geofence is triggered
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.destinationGeofenceDidTrigger).sink { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard beacon?.routeDetail == nil else {
                // Ignore notifications from `DestinationManager` if the beacons
                // are following a route
                return
            }
            
            guard let userInfo = notification.userInfo as? [String: Any] else {
                return
            }
            
            guard let isAudioEnabled = userInfo[DestinationManager.Keys.isAudioEnabled] as? Bool else {
                return
            }
            
            // Update `isAudioEnabled`
            self.beacon?.isAudioEnabled = isAudioEnabled
        })
        
        // Audio beacon has been added, changed or removed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.destinationChanged).sink { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            if beacon?.routeDetail == nil {
                // Listen to notifications from `DestinationManager` if the beacons
                // are following a route
                if let userInfo = notification.userInfo as? [String: Any],
                   let key = userInfo[DestinationManager.Keys.destinationKey] as? String,
                   let beacon = SpatialDataCache.referenceEntityByKey(key),
                   let isAudioEnabled = userInfo[DestinationManager.Keys.isAudioEnabled] as? Bool {
                    // Beacon was set - Update beacon so that it is placed on the new location
                    self.beacon = BeaconDetail(locationDetail: LocationDetail(marker: beacon), isAudioEnabled: isAudioEnabled)
                } else {
                    // Beacon was removed
                    self.beacon = nil
                }
            } else {
                // If the beacons are following a route, ignore destination changes,
                // but listen to changes in `isAudioEnabled`
                if let userInfo = notification.userInfo as? [String: Any],
                   let isAudioEnabled = userInfo[DestinationManager.Keys.isAudioEnabled] as? Bool {
                    // Route beacon was set
                    self.beacon?.isAudioEnabled = isAudioEnabled
                } else {
                    // Route beacon transition
                    // Audio was disabled
                    self.beacon?.isAudioEnabled = false
                }
            }
            
        })
        
        // Behavior is activated
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.behaviorActivated).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard let behavior = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance else {
                return
            }
            
            // Route guidance has started - Update the beacon so that it is placed
            // on the route's current waypoint
            self.beacon = BeaconDetail(from: behavior, isAudioEnabled: true)
        })
        
        // State of activated behavior has changed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.routeGuidanceStateChanged).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard let route = beacon?.routeDetail?.guidance else {
                return
            }
            
            // Route guidance is in-progress - Update the beacon so that
            // it is placed on the new, current waypoint
            self.beacon = BeaconDetail(from: route, isAudioEnabled: true)
        })
        
        // Behavior is deactivated
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.behaviorDeactivated).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard beacon?.routeDetail != nil else {
                return
            }
            
            // Route guidance has ended
            self.beacon = nil
        })
        
        // Location updated
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.locationUpdated).sink(receiveValue: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            guard let oldValue = self.beacon else {
                return
            }
            
            let newValue = BeaconDetail.updateLocationDetailIfNeeded(for: oldValue)
            
            guard newValue.locationDetail.source != oldValue.locationDetail.source || newValue.locationDetail.location.coordinate != oldValue.locationDetail.location.coordinate else {
                return
            }
            
            self.beacon = newValue
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .routeGuidanceTransitionStateChanged).receive(on: RunLoop.main).sink { [weak self] notification in
            guard let transState = notification.userInfo?[RouteGuidance.Key.isTransitioning] as? Bool else {
                return
            }
            
            self?.isRouteTransitioning = transState
        })
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
}
