//
//  RouteGuidanceGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class RouteGuidanceReadyEvent: StateChangedEvent { }

class BeginWaypointDistanceCalloutsEvent: StateChangedEvent {
    let userLocation: CLLocation
    let waypointLocation: CLLocation
    
    init(user: CLLocation, waypoint: CLLocation) {
        userLocation = user
        waypointLocation = waypoint
    }
}

class WaypointArrivalEvent: StateChangedEvent {
    let progress: RouteProgress
    
    init(_ progress: RouteProgress) {
        self.progress = progress
    }
}

class WaypointDepartureEvent: StateChangedEvent {
    let progress: RouteProgress
    
    init(_ progress: RouteProgress) {
        self.progress = progress
    }
}

extension Notification.Name {
    static let routeWaypointArrived = Notification.Name("GDARouteWaypointArrivalOccurred")
}

class RouteGuidanceGenerator: AutomaticGenerator, ManualGenerator {
    
    struct Key {
        static let markerId = "markerId"
    }

    private let distanceCalloutFilter: BeaconUpdateFilter
    private let arrivalDistance: CLLocationDistance = 12.0
    
    private var currentActivationGroupID: UUID?
    private var currentArrivalGroupID: UUID?
    private var currentDepartureGroupID: UUID?
    private var currentDistanceGroupID: UUID?
    private var currentIntersectionGroupID: UUID?
    
    private var isGuidanceReady: Bool = false
    private var lastWaypoint: (index: Int, waypoint: LocationDetail)?
    private var lastWasPreviouslyVisited: Bool = false
    private let alreadyCompleted: Bool
    private var shouldDeactivate: Bool = false
    private var awaitingNextWaypoint: Bool = true
    
    /// Flag that indicates when the generator is currently awaiting departure callouts to complete. This
    /// is set to `true` when arrival callouts have been triggered (meaning the asynchronous process that
    /// will result in departure callouts eventually has been initiated). Waypoint distance callouts should
    /// not occur when this flag is set to `true`.
    private var awaitingDepartureCalloutCompletion = false
    
    private var pendingIntersectionArrivalEvent: IntersectionArrivalEvent?
    private var pendingWaypointArrivalEvent: WaypointArrivalEvent?
    
    var canInterrupt: Bool = false
    
    private unowned let owner: RouteGuidance
    
    init(_ owner: RouteGuidance, motionActivity: MotionActivityProtocol, alreadyCompleted: Bool) {
        self.owner = owner
        self.alreadyCompleted = alreadyCompleted
        distanceCalloutFilter = BeaconUpdateFilter(updateDistance: 10.0 ..< 25.0, beaconDistance: 12.0 ..< 100.0, motionActivity: motionActivity)
    }
    
    func cancelCalloutsForEntity(id: String) {
        // Intentional No-Op
    }
    
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        return event is BehaviorActivatedEvent
    }
    
    func respondsTo(_ event: StateChangedEvent) -> Bool {
        switch event {
        case is LocationUpdatedEvent,
            is RouteGuidanceReadyEvent,
            is BeginWaypointDistanceCalloutsEvent,
            is WaypointArrivalEvent,
            is WaypointDepartureEvent,
            is IntersectionArrivalEvent:
            return true
            
        default:
            return false
        }
    }
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case is BehaviorActivatedEvent:
            owner.addBlocked(auto: AutoCalloutGenerator.self)
            return .noAction
            
        default:
            return nil
        }
    }
    
    func handle(event: StateChangedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let locationEvent as LocationUpdatedEvent:
            guard isGuidanceReady else {
                return nil
            }
            
            // Ignore location updates while we are waiting for the arrival callouts and subsequent departure
            // callouts to finish (i.e. when we are transitioning between beacons).
            guard !awaitingNextWaypoint else {
                return nil
            }
            
            // Check to see if the user has arrived at the current waypoint. Rather than directly generating
            // callouts now, instead signal to the RouteGuidance behavior that the current waypoint has been
            // completed. This will cause the current beacon to be finished (playing the arrival melody) and
            // then the WaypointArrivalEvent will be sent, causing the actual arrival callouts to be generated.
            if checkArrival(for: locationEvent, verbosity: verbosity) {
                awaitingNextWaypoint = true
                return .noAction
            }
            
            // Don't start doing waypoint distance callouts until the departure callouts are complete
            guard !awaitingDepartureCalloutCompletion else {
                return .noAction
            }
            
            guard let callouts = generateDistanceCallouts(for: locationEvent, verbosity: verbosity) else {
                return .noAction
            }
            
            return .playCallouts(callouts)
        
        case is RouteGuidanceReadyEvent:
            isGuidanceReady = true
            
            let progress = owner.progress
            
            var callouts: [CalloutProtocol] = []
            
            if let current = owner.currentWaypoint {
                callouts.append(WaypointDepartureCallout(index: current.index,
                                                         waypoint: current.waypoint,
                                                         progress: progress,
                                                         isAutomatic: false))
            } else {
                callouts.append(StringCallout(.routeGuidance, GDLocalizedString("behavior.scavenger_hunt.callout.started")))
            }
            
            let group = CalloutGroup(callouts, action: .interruptAndClear, playModeSounds: false, logContext: "scavenger_hunt.hunt_started")
            currentActivationGroupID = group.id
            group.delegate = self
            
            return .playCallouts(group)
            
        case let event as BeginWaypointDistanceCalloutsEvent:
            // Initialize the beacon callouts for the current beacon
            distanceCalloutFilter.start(beaconLocation: event.waypointLocation, shouldIgnoreFirstUpdate: true)
            awaitingNextWaypoint = false
            return .noAction
            
        case let event as WaypointArrivalEvent:
            guard currentIntersectionGroupID == nil else {
                awaitingDepartureCalloutCompletion = true
                pendingWaypointArrivalEvent = event
                return .noAction
            }
            
            guard let callouts = generateArrivalCallouts(event) else {
                return .noAction
            }
            
            return .playCallouts(callouts)
            
        case let event as WaypointDepartureEvent:
            guard let callouts = generateDepartureCallouts(event) else {
                return .noAction
            }
            
            return .playCallouts(callouts)
            
        case let event as IntersectionArrivalEvent:
            // If we are in the middle of a transition between beacons, or we are performing the
            // initial callouts when the route starts, we should wait to do the intersection callout
            // so it doesn't interrupt
            guard !awaitingDepartureCalloutCompletion && currentActivationGroupID == nil else {
                pendingIntersectionArrivalEvent = event
                return .noAction
            }
            
            let callout = IntersectionCallout(.intersection, event.key, event.isRoundabout, event.heading)
            
            GDATelemetry.track("callout", with: ["context": "intersection.arrival",
                                                 "type": callout.logCategory,
                                                 "activity": AppContext.shared.motionActivityContext.currentActivity.rawValue,
                                                 "audio.output": AppContext.shared.audioEngine.outputType])
            
            let group = CalloutGroup([callout], action: .interruptAndClear, logContext: "intersections")
            currentIntersectionGroupID = group.id
            group.delegate = self
            return .playCallouts(group)
            
        default:
            return nil
        }
    }
    
    private func checkArrival(for locationEvent: LocationUpdatedEvent, verbosity: Verbosity) -> Bool {
        // Make sure we currently have a flag
        guard let current = owner.currentWaypoint  else {
            return false
        }
        
        let distance = locationEvent.location.distance(from: current.waypoint.location)
        
        // When the user gets within 40 meters of the waypoint, block other callouts to prevent
        // the route guidance callouts from being poorly timed.
        if distance < 40.0 && !owner.blockedAutoGenerators.contains(where: { $0 == AutoCalloutGenerator.self }) {
            GDLogInfo(.routeGuidance, "Blocking auto callouts")
            owner.addBlocked(auto: AutoCalloutGenerator.self)
        }
        
        guard distance < arrivalDistance else {
            return false
        }
        
        return arrive(at: current, userLocation: locationEvent.location)
    }
    
    private func arrive(at current: (index: Int, waypoint: LocationDetail), userLocation: CLLocation) -> Bool {
        let previouslyVisited = owner.state.visited.contains(current.index)
        
        // Complete the current flag and get the progress object
        guard owner.completeCurrentWaypoint() else {
            return false
        }
        
        lastWaypoint = current
        lastWasPreviouslyVisited = previouslyVisited
        
        // Update the distance callout filter since this callout also includes a distance component
        distanceCalloutFilter.didUpdate(location: userLocation, success: true)
        
        return true
    }
    
    private func generateArrivalCallouts(_ event: WaypointArrivalEvent) -> CalloutGroup? {
        guard let previous = lastWaypoint else {
            return nil
        }
        
        // Let the automatic callout context know that this marker has been called out so it doesn't
        // also attempt to call it out
        if let id = previous.waypoint.markerId {
            NotificationCenter.default.post(name: .routeWaypointArrived, object: nil, userInfo: [Key.markerId: id])
        }
        
        awaitingDepartureCalloutCompletion = true
        
        let callouts: [CalloutProtocol]  = [
            WaypointArrivalCallout(index: previous.index,
                                   waypoint: previous.waypoint,
                                   progress: event.progress,
                                   previouslyVisited: lastWasPreviouslyVisited,
                                   isAdaptiveSportsActivity: owner.isAdaptiveSportsEvent)
        ]
        
        let group = CalloutGroup(callouts, logContext: "route_guidance.arrival_callout")
        
        currentArrivalGroupID = group.id
        group.delegate = self
        
        GDLogInfo(.routeGuidance, "Created arrival callout group \(group.id)")
        
        if event.progress.isDone {
            shouldDeactivate = true
        }
        
        return group
    }
    
    private func generateDepartureCallouts(_ event: WaypointDepartureEvent) -> CalloutGroup? {
        guard let next = event.progress.currentWaypoint else {
            return nil
        }
        
        let callouts: [CalloutProtocol] = [
            WaypointDepartureCallout(index: next.index,
                                     waypoint: next.waypoint,
                                     progress: event.progress,
                                     isAutomatic: true)
        ]
        
        let group = CalloutGroup(callouts, logContext: "route_guidance.departure_callout")
        
        currentDepartureGroupID = group.id
        group.delegate = self
        
        GDLogInfo(.routeGuidance, "Created departure callout group \(group.id)")
        
        return group
    }
    
    private func generateDistanceCallouts(for locationEvent: LocationUpdatedEvent, verbosity: Verbosity) -> CalloutGroup? {
        guard distanceCalloutFilter.shouldUpdate(location: locationEvent.location) else {
            return nil
        }
        
        // Make sure we currently have a flag
        guard let current = owner.currentWaypoint else {
            return nil
        }
        
        // User has passed the distance limits so we should do another distance callout
        distanceCalloutFilter.isUpdating(location: locationEvent.location)
        
        let callouts = [WaypointDistanceCallout(index: current.index, waypoint: current.waypoint)]
        let group = CalloutGroup(callouts, logContext: "route_guidance.distance_callout")
        
        currentDistanceGroupID = group.id
        group.delegate = self
        
        GDLogInfo(.routeGuidance, "Created distance callout group \(group.id)")
        
        return group
    }
}

extension RouteGuidanceGenerator: CalloutGroupDelegate {
    
    func isCalloutWithinRegionToLive(_ callout: CalloutProtocol) -> Bool {
        return true
    }
    
    func calloutSkipped(_ callout: CalloutProtocol) {
        // No-Op
    }
    
    func calloutStarting(_ callout: CalloutProtocol) {
        // No-op
    }
    
    func calloutFinished(_ callout: CalloutProtocol, completed: Bool) {
        // No-op
    }
    
    func calloutsSkipped(for group: CalloutGroup) {
        clearFilter(for: group)
        GDLogInfo(.routeGuidance, "Callouts skipped \(group.id)")
    }
    
    func calloutsStarted(for group: CalloutGroup) {
        GDLogInfo(.routeGuidance, "Callouts started \(group.id)")
    }
    
    func calloutsCompleted(for group: CalloutGroup, finished: Bool) {
        defer {
            clearFilter(for: group)
        }
        
        GDLogInfo(.routeGuidance, "Callouts completed \(group.id)")
        
        switch group.id {
        case currentActivationGroupID:
            owner.removeBlocked(auto: AutoCalloutGenerator.self)
            
            // If there is a pending intersection arrival callout, process it now
            if let pending = pendingIntersectionArrivalEvent {
                pendingIntersectionArrivalEvent = nil
                
                DispatchQueue.main.async { [weak self] in
                    self?.owner.delegate?.process(pending)
                }
            }
            
        case currentIntersectionGroupID:
            if let pending = pendingWaypointArrivalEvent {
                pendingWaypointArrivalEvent = nil
                
                DispatchQueue.main.async { [weak self] in
                    self?.owner.delegate?.process(pending)
                }
            }
            
        case currentDepartureGroupID:
            // After departure callouts are finished, we can let regular automatic callouts resume again
            if owner.blockedAutoGenerators.contains(where: { $0 == AutoCalloutGenerator.self }) {
                GDLogInfo(.routeGuidance, "Allow auto callouts again")
                owner.removeBlocked(auto: AutoCalloutGenerator.self)
            }
            
            // Allow distance callouts to resume
            awaitingDepartureCalloutCompletion = false
            
            // If there is a pending intersection arrival callout, process it now
            if let pending = pendingIntersectionArrivalEvent {
                pendingIntersectionArrivalEvent = nil
                
                DispatchQueue.main.async { [weak self] in
                    self?.owner.delegate?.process(pending)
                }
            }
            
        case currentArrivalGroupID:
            guard !alreadyCompleted else {
                return
            }
            
            if shouldDeactivate {
                AppContext.shared.eventProcessor.deactivateCustom()
            } else {
                // Do this off the main queue so that we don't attempt to process a departure event from within
                // the `calloutsCompleted(for:finished:)` callback for the arrival callout.
                DispatchQueue.main.async { [weak self] in
                    self?.owner.finishTransitioningBeacon()
                }
            }
            
        default:
            break
        }
    }
    
    private func clearFilter(for group: CalloutGroup) {
        // Signal to the appropriate filter that the update is done
        if let id = currentDistanceGroupID, group.id == id {
            distanceCalloutFilter.didUpdate(success: true)
            currentDistanceGroupID = nil
        } else if let id = currentDepartureGroupID, group.id == id {
            currentDepartureGroupID = nil
        } else if let id = currentArrivalGroupID, group.id == id {
            currentArrivalGroupID = nil
        } else if let id = currentActivationGroupID, group.id == id {
            currentActivationGroupID = nil
        } else if let id = currentIntersectionGroupID, group.id == id {
            currentIntersectionGroupID = nil
        }
    }
}
