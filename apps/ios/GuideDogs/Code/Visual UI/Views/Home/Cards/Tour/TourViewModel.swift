//
//  TourViewModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

class TourViewModel: ObservableObject {
    
    // MARK: Properties
    
    @Published private var currentWaypointIndex: Int?
    @Published private(set) var isDepartedForCurrentWaypoint = true
    @Published private(set) var isAudioBeaconEnabled = false
    @Published private(set) var isTransitioning = false
    @Published private(set) var isComplete = false
    
    private let tour: GuidedTour
    private var listeners: [AnyCancellable] = []
    
    var nCompleted: Int {
        return isComplete ? nWaypoint : currentWaypointIndex ?? 0
    }
    
    var nWaypoint: Int {
        return tour.content.waypoints.count
    }
    
    var currentWaypointLocation: LocationDetail? {
        return currentWaypointDetail?.locationDetail
    }
    
    var currentWaypointDetail: WaypointDetail? {
        guard let index = currentWaypointIndex else {
            return nil
        }
        
        return WaypointDetail(index: index, routeDetail: tour.content)
    }
    
    var isFirstWaypoint: Bool {
        return currentWaypointIndex == 0
    }
    
    var isLastWaypoint: Bool {
        return currentWaypointIndex == nWaypoint - 1
    }
    
    // MARK: Initialization
    
    init(tour: GuidedTour) {
        self.tour = tour
        
        // Initialize published properties
        updatePublishedProperties()
        
        // Behavior is activated
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.behaviorActivated).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            // Tour has started
            // Update published properties
            self.updatePublishedProperties()
        })
        
        // Behavior is deactivated
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.behaviorDeactivated).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            // Tour has ended
            // Update published properties
            self.updatePublishedProperties()
        })
        
        // Audio beacon is muted or unmuted
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.destinationAudioChanged).receive(on: RunLoop.main).sink { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard let userInfo = notification.userInfo as? [String: Any] else {
                return
            }
            
            guard let isAudioBeaconEnabled = userInfo[DestinationManager.Keys.isAudioEnabled] as? Bool else {
                return
            }
            
            // Update `isAudioBeaconEnabled`
            self.isAudioBeaconEnabled = isAudioBeaconEnabled
        })
        
        // Tour state has changed
        listeners.append(NotificationCenter.default.publisher(for: Notification.Name.tourStateChanged).receive(on: RunLoop.main).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            self.updatePublishedProperties()
        })
        
        // Tour is transitioning between waypoints
        listeners.append(NotificationCenter.default.publisher(for: .tourTransitionStateChanged).receive(on: RunLoop.main).sink { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard let isTransitioning = notification.userInfo?[RouteGuidance.Key.isTransitioning] as? Bool else {
                return
            }
            
            self.isTransitioning = isTransitioning
            self.updatePublishedProperties()
        })
        
        // Tour `hasDepartedForCurrentWaypoint` has changed
        listeners.append(NotificationCenter.default.publisher(for: .tourHasDepartedChanged).receive(on: RunLoop.main).sink(receiveValue: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            self.updatePublishedProperties()
        }))
    }
    
    private func updatePublishedProperties() {
        if tour.isActive {
            isComplete = tour.state.isFinal
            currentWaypointIndex = tour.currentWaypoint?.index
            isDepartedForCurrentWaypoint = tour.hasDepartedForCurrentWaypoint
            isAudioBeaconEnabled = AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled
        } else {
            // Default values
            isComplete = false
            currentWaypointIndex = nil
            isDepartedForCurrentWaypoint = true
            isAudioBeaconEnabled = false
            isTransitioning = false
        }
    }
    
}
