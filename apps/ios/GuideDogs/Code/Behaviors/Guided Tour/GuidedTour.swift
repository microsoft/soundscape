//
//  TourGuide.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import Combine

struct TourProgress {
    let currentWaypoint: (index: Int, waypoint: LocationDetail)?
    let completed: Int
    let total: Int
    let isDone: Bool
    
    var remaining: Int {
        return total - completed
    }
    
    var percentComplete: Int {
        return (completed * 100 / total)
    }
}

extension Notification.Name {
    static let tourStateChanged = Notification.Name("GDATourStateChanged")
    static let tourTransitionStateChanged = Notification.Name("GDATourTransitionStateChanged")
    static let tourHasDepartedChanged = Notification.Name("GDATourHasDepartedChanged")
    static let tourWillEnd = Notification.Name("GDATourWillEnd")
}

struct TourState: Codable, CustomStringConvertible {
    var contentId: String
    
    /// A running counter of the ammount of time a user has spent in the event route
    var totalTime: TimeInterval = 0.0
    
    /// Indicates if the totalTime property is the final time (e.g. the user has completed the event route and
    /// the totalTime should no longer be increased)
    var isFinal: Bool = false
    
    /// The index of the current waypoint the user has set
    var waypointIndex: Int?
    
    /// Indexes of waypoints that have been visited by the user
    var visited: [Int] = []
    
    var description: String {
        var desc = "State: (Guided Tour \(contentId))\n"
        
        desc.append("\n\tTotal Time: \(totalTime)\n")
        desc.append("\tWaypoint Index: \(waypointIndex ?? -1)\n")
        desc.append("\tVisited Indices: \(visited)\n")
        
        return desc
    }
    
    init(id: String) {
        contentId = id
    }
}

class GuidedTour: BehaviorBase {
    
    struct PendingBeaconArgs {
        let id: UUID
        let waypoint: LocationDetail
        let enableAudio: Bool
    }
    
    struct Key {
        static let isTransitioning = "isTransitioning"
    }
    
    static let name = "RouteGuidance"
    
    private unowned let spatialDataContext: SpatialDataProtocol
    private unowned let motionActivity: MotionActivityProtocol
        
    var state: TourState
    private(set) var content: TourDetail
    private(set) var nearestIntersectionKey: String?
    
    private var pendingBeaconArgs: PendingBeaconArgs?
    private var isArrivingAtWaypoint = false
    private var arrivedAtFinalWaypoint = false
    private var isFinished = false
    private var beaconObserver: AnyCancellable?
    // Unless `shouldResume = true`, the route's state will be reset each time
    // the route is activated
    var shouldResume = false
    
    private var lastSaveTime: Date?
    var runningTime: TimeInterval {
        guard !state.isFinal else {
            return state.totalTime
        }
        
        guard let lastSaveTime = lastSaveTime else {
            return state.totalTime
        }
        
        return state.totalTime + Date().timeIntervalSince(lastSaveTime)
    }
    
    var progress: TourProgress {
        return TourProgress(currentWaypoint: currentWaypoint, completed: state.visited.count, total: content.waypoints.count, isDone: arrivedAtFinalWaypoint)
    }
    
    var hasDepartedForCurrentWaypoint: Bool = true {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tourHasDepartedChanged, object: nil)
            }
        }
    }
    
    var currentWaypoint: (index: Int, waypoint: LocationDetail)? {
        guard let index = state.waypointIndex, index >= 0, index < content.waypoints.count else {
            return nil
        }
        
        return (index: index, waypoint: content.waypoints[index])
    }
    
    private var isBeaconAsync: Bool {
        return spatialDataContext.destinationManager.isCurrentBeaconAsyncFinishable
    }
    
    private var isBeaconAudioEnabled: Bool {
        return spatialDataContext.destinationManager.isAudioEnabled
    }
    
    let telemetryContext: String = "tourguide"
    
    init(_ detail: TourDetail, spatialData: SpatialDataProtocol, motion: MotionActivityProtocol) {
        self.content = detail
        self.state = TourState(id: detail.id)
        self.spatialDataContext = spatialData
        self.motionActivity = motion
        
        super.init(blockedAutoGenerators: [BeaconCalloutGenerator.self], blockedManualGenerators: [BeaconCalloutGenerator.self])
    }
    
    convenience init(_ event: AuthoredActivityContent, spatialData: SpatialDataProtocol, motion: MotionActivityProtocol) {
        let detail = TourDetail(content: event)
        self.init(detail, spatialData: spatialData, motion: motion)
    }
    
    override func activate(with parent: Behavior?) {
        let gen = TourGenerator(self, motionActivity: motionActivity, alreadyCompleted: progress.isDone)
        
        manualGenerators.append(gen)
        autoGenerators.append(gen)
        
        if shouldResume {
            // Do not reset the route state
            // Reset `shouldResume`
            shouldResume = false
        } else {
            // Reset the route state
            state.totalTime = 0.0
            state.isFinal = false
            state.waypointIndex = 0
            state.visited = []
            NotificationCenter.default.post(name: Notification.Name.tourStateChanged, object: self)
        }
        
        // Make sure the initial waypoint is set (either it is already set from a loaded state file, or we set it to zero
        if state.waypointIndex == nil {
            state.waypointIndex = 0
        }
        
        // For the time being, always set the beacon immediately
        guard let current = currentWaypoint else {
            return
        }
        
        // Make sure there isn't an existing beacon when we start the first route beacon
        if spatialDataContext.destinationManager.isDestinationSet {
            do {
                try spatialDataContext.destinationManager.clearDestination()
            } catch {
                GDLogError(.routeGuidance, "Unable to stop the existing beacon!")
            }
        }
        
        nearestIntersectionKey = findNearestIntersection()
        
        setOrTransitionBeacon(to: current.waypoint)
        saveState()
        lastSaveTime = Date()
        
        beaconObserver = NotificationCenter.default.publisher(for: Notification.Name.dynamicPlayerFinished).receive(on: RunLoop.main).sink { notification in
            guard !self.isFinished else {
                return
            }
            
            // and there is a pending beacon...
            guard let args = self.pendingBeaconArgs else {
                if self.progress.isDone {
                    self.isFinished = true
                    
                    // Play the final arrival callouts
                    self.delegate?.process(TourWaypointArrivalEvent(self.progress))
                }
                
                return
            }
            
            // When the beacon has been removed...
            guard notification.userInfo?[AudioEngine.Keys.playerId] as? UUID == args.id else {
                return
            }
            
            if self.isArrivingAtWaypoint {
                // Play the arrival callouts and then finish setting the new beacon
                self.delegate?.process(TourWaypointArrivalEvent(self.progress))
            } else {
                // Directly set the next beacon (the user used next/previous to change the beacon)
                self.finishTransitioningBeacon(automatic: false)
            }
        }
        
        super.activate(with: parent)
        GDATelemetry.track("tourguide.started", with: ["context": telemetryContext])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            guard let location = AppContext.shared.geolocationManager.location else {
                return
            }
            
            GDLogVerbose(.routeGuidance, "Registering \(self.content.event.pois.count) prioritized POIs for tour")
            if self.content.event.pois.count > 0 {
                self.delegate?.process(RegisterPrioritizedPOIs(pois: self.content.event.pois))
            }
            
            self.delegate?.process(TourReadyEvent())
            self.delegate?.process(BeginTourWaypointDistanceCalloutsEvent(user: location, waypoint: current.waypoint.location))
        }
    }
    
    override func deactivate() -> Behavior? {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .tourWillEnd, object: nil)
        }
        
        beaconObserver?.cancel()
        beaconObserver = nil
        
        nearestIntersectionKey = nil
        
        saveState()
        clearBeacon()
        updateNowPlayingInfo(nil)
        
        GDATelemetry.track("tourguide.stopped", with: ["context": telemetryContext, "completed": String(state.isFinal)])
        
        DispatchQueue.main.async {
            AppContext.process(RemoveRegisteredPOIs())
        }
        
        return super.deactivate()
    }
    
    override func sleep() {
        super.sleep()
        
        // Ensure the beacon audio turns off when the app enters sleep mode
        if spatialDataContext.destinationManager.isAudioEnabled {
            spatialDataContext.destinationManager.toggleDestinationAudio(forceMelody: false)
        }
        
        saveState()
    }
    
    override func wake() {
        // Reset the last save time so that we don't track all the time the app was asleep
        lastSaveTime = Date()
        
        super.wake()
        
        // Ensure the beacon audio turns on when the app wakes up
        spatialDataContext.destinationManager.toggleDestinationAudio(forceMelody: true)
    }
    
    /// Adds the index of the current waypoint to the visited waypoints and then switches to
    /// the next waypoint.
    ///
    /// - Returns:
    func completeCurrentWaypoint() -> Bool {
        guard let index = state.waypointIndex else {
            return false
        }
        
        // If this waypoint was already completed, then just move onto the next one
        guard !state.visited.contains(index) else {
            GDATelemetry.track("tourguide.waypoint_revisited", with: ["context": telemetryContext])
            nextWaypoint(automatic: true)
            return true
        }
        
        state.visited.append(index)
        GDATelemetry.track("tourguide.waypoint_visited", with: ["context": telemetryContext])
        
        // If the route is complete, turn off the audio beacon. The beacon will still be set on the last waypoint, but the
        // audio will be disabled. The user can turn it on if they wish.
        guard index != content.waypoints.count - 1 else {
            GDATelemetry.track("tourguide.final_waypoint.arrival")
            
            arrivedAtFinalWaypoint = true
            
            if isBeaconAsync && isBeaconAudioEnabled {
                // Toggle off the beacon's audio. As soon as it finishes playing the ending melody,
                // we will trigger the arrival callouts
                spatialDataContext.destinationManager.toggleDestinationAudio(false, forceMelody: true)
            } else {
                if !isBeaconAsync && isBeaconAudioEnabled {
                    spatialDataContext.destinationManager.toggleDestinationAudio(false, forceMelody: true)
                }
                
                // If the beacon is already muted, then we should go ahead and play the arrival callouts
                // without waiting for the beacon to stop
                isFinished = true
                let event = TourWaypointArrivalEvent(self.progress)
                
                DispatchQueue.main.async {
                    self.delegate?.process(event)
                }
            }
            
            nearestIntersectionKey = nil
            saveState(finalize: true)
            GDATelemetry.track("tourguide.completed", with: ["context": telemetryContext])
            return true
        }
        
        // Update to the next waypoint and save the route guidance state
        nextWaypoint(automatic: true)
        return true
    }
    
    func finishTransitioningBeacon(automatic: Bool = true) {
        // and there is a pending beacon...
        guard let args = self.pendingBeaconArgs else {
            return
        }
        
        // start the pending beacon
        self.pendingBeaconArgs = nil
        self.completeSetBeacon(waypoint: args.waypoint, enableAudio: args.enableAudio)
        
        // Only send the departure event if the user tapped next/previous. Otherwise this will be handled
        // when the user actually departs the waypoint they just arrived at.
        if !automatic {
            self.delegate?.process(TourWaypointDepartureEvent(progress))
        }
    }
    
    func repeatLastBeaconCallout() {
        self.delegate?.interruptCurrent(clearQueue: true, playHush: false)
        
        if state.waypointIndex == 0 || hasDepartedForCurrentWaypoint {
            self.delegate?.process(TourWaypointDepartureEvent(progress))
        } else {
            self.delegate?.process(TourWaypointArrivalEvent(progress))
        }
    }
    
    /// Updates the `waypointIndex` property of the state object to be the index of the
    /// next waypoint and then saves the route guidance's state.
    func nextWaypoint(automatic: Bool = false) {
        if let index = state.waypointIndex {
            // Next() increases the index until the last index and then stops incrementing
            state.waypointIndex = min(index + 1, content.waypoints.count - 1)
        } else {
            // If the waypointIndex is currently nil, then default to 0
            state.waypointIndex = 0
        }
        
        // If the user manually tapped the "Next" button, then hush and current callouts so the
        // departure callouts happen immediately and don't queue
        if !automatic {
            delegate?.interruptCurrent(clearQueue: true, playHush: false)
        }
        
        if let current = currentWaypoint {
            updateNowPlayingInfo(current)
            isArrivingAtWaypoint = automatic
            setOrTransitionBeacon(to: current.waypoint, skipAsyncFinish: !automatic)
            
            GDLogInfo(.routeGuidance, "Tour Guide: Current waypoint is #\(current.index)")
        } else {
            GDLogInfo(.routeGuidance, "Tour Guide: Current waypoint is not known")
        }
        
        nearestIntersectionKey = findNearestIntersection()
        
        // Save state after everything else so that the stateChanged event gets sent when all state is done changing
        saveState()
        
        GDATelemetry.track("tourguide.next", with: ["context": telemetryContext, "automatic": "\(automatic)", "activity": AppContext.shared.motionActivityContext.currentActivity.rawValue])
    }
    
    /// Updates the `waypointIndex` property of the state object to be the index of the
    /// previous waypoint and then saves the route guidance's state.
    func previousWaypoint() {
        if let index = state.waypointIndex {
            // Decrement the waypoint index down to zero, but don't go beyond zero
            state.waypointIndex = max(index - 1, 0)
        } else {
            // If the waypointIndex hasn't been set yet, initialize it to 0.
            state.waypointIndex = 0
        }
        
        nearestIntersectionKey = findNearestIntersection()
        
        saveState()
        
        if let current = currentWaypoint {
            updateNowPlayingInfo(current)
            isArrivingAtWaypoint = false
            
            delegate?.interruptCurrent(clearQueue: true, playHush: false)
            setOrTransitionBeacon(to: current.waypoint, skipAsyncFinish: true)
            
            GDLogInfo(.routeGuidance, "Tour Guide: Current waypoint is #\(current.index)")
        } else {
            GDLogInfo(.routeGuidance, "Tour Guide: Current waypoint is not known")
        }
        
        GDATelemetry.track("tourguide.previous", with: ["context": telemetryContext, "activity": AppContext.shared.motionActivityContext.currentActivity.rawValue])
    }
    
    func setBeacon(waypointIndex index: Int, enableAudio: Bool = true) {
        guard index < content.waypoints.count else {
            return
        }
        
        state.waypointIndex = index
        let waypoint = content.waypoints[index]
        setOrTransitionBeacon(to: waypoint, enableAudio: enableAudio)
        
        nearestIntersectionKey = findNearestIntersection()
        
        saveState()
    }
    
    private func setOrTransitionBeacon(to waypoint: LocationDetail, enableAudio: Bool = true, skipAsyncFinish: Bool = false) {
        hasDepartedForCurrentWaypoint = false
        
        // Notify the UI that we are transitioning between beacon locations
        NotificationCenter.default.post(name: .tourTransitionStateChanged, object: nil, userInfo: [Key.isTransitioning: true])
        
        // Check if a beacon has already been set - meaning that we are transitioning from one waypoint to another
        guard AppContext.shared.spatialDataContext.destinationManager.isDestinationSet else {
            completeSetBeacon(waypoint: waypoint, enableAudio: enableAudio)
            return
        }
        
        // Ensure the beacon audio turns off when the app enters sleep mode
        if skipAsyncFinish && isBeaconAudioEnabled {
            // Toggle the audio off so that the next beacon starts immediately
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio(forceMelody: false)
        }
        
        // Make sure the beacon is currently playing
        guard isBeaconAsync, let id = AppContext.shared.spatialDataContext.destinationManager.beaconPlayerId else {
            if !isBeaconAsync && isBeaconAudioEnabled {
                AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio(false, forceMelody: true)
            }
            
            let event: Event
            if isArrivingAtWaypoint {
                // If arriving when the beacon is muted, then kick off the arrival callouts immediately
                pendingBeaconArgs = .init(id: UUID(), waypoint: waypoint, enableAudio: enableAudio)
                event = TourWaypointArrivalEvent(progress)
            } else {
                // If pressing the next button when the beacon is muted, then kick off the waypoint
                // departure callouts for the next waypoint immediately
                completeSetBeacon(waypoint: waypoint, enableAudio: enableAudio)
                event = TourWaypointDepartureEvent(progress)
            }
            
            DispatchQueue.main.async {
                self.delegate?.process(event)
            }
            
            return
        }
        
        // Otherwise, we need to start the transition from the beacon for the previous waypoint
        // to the beacon for the subsequent waypoint by first stopping the current beacon. So save
        // the arguments for the next beacon and clear the current beacon. As soon as the beacon is
        // stopped, we will complete the process to start the next beacon.
        pendingBeaconArgs = .init(id: id, waypoint: waypoint, enableAudio: enableAudio)
        
        GDLogInfo(.routeGuidance, "Start transition to next tour beacon...")
        
        do {
            try AppContext.shared.spatialDataContext.destinationManager.clearDestination(logContext: "tourguide.set_beacon")
            GDLogInfo(.routeGuidance, "Awaiting finish of current tour beacon...")
        } catch {
            GDLogError(.routeGuidance, "Error: Unable to remove current beacon in Tour Guidance!")
        }
    }
    
    private func completeSetBeacon(waypoint: LocationDetail, enableAudio: Bool) {
        guard let userLocation = AppContext.shared.geolocationManager.location else {
            return
        }
        
        guard let location = waypoint.source.closestLocation(from: userLocation, useEntranceIfAvailable: true) else {
            return
        }
        
        // Start checking for distance callouts when we set the beacon
        delegate?.process(BeginTourWaypointDistanceCalloutsEvent(user: userLocation, waypoint: location))
        
        do {
            let manager = spatialDataContext.destinationManager
            
            if let markerId = waypoint.markerId {
                try manager.setDestination(referenceID: markerId, enableAudio: enableAudio, userLocation: userLocation, logContext: "route")
            } else {
                try manager.setDestination(location: location, behavior: waypoint.displayName, enableAudio: enableAudio, userLocation: userLocation, logContext: "route")
            }
            
            // Ensure the beacon audio turns on when the waypoint changes
            if enableAudio && !manager.isAudioEnabled {
                manager.toggleDestinationAudio(forceMelody: true)
            }
            
            if let current = currentWaypoint {
                updateNowPlayingInfo(current)
            }
            
            GDLogInfo(.routeGuidance, "Finished setting route beacon")
        } catch {
            GDLogError(.routeGuidance, "Error: Unable to set beacon in Route Guidance!")
        }
        
        // Once the new beacon has been set, indicate that the transition is complete
        NotificationCenter.default.post(name: .tourTransitionStateChanged, object: nil, userInfo: [Key.isTransitioning: false])
    }
    
    private func clearBeacon() {
        if spatialDataContext.destinationManager.isDestinationSet {
            do {
                try spatialDataContext.destinationManager.clearDestination(logContext: "route")
                GDLogInfo(.routeGuidance, "Cleared route beacon")
            } catch {
                GDLogError(.routeGuidance, "Error: Unable to clear beacon in Route Guidance!")
            }
        }
    }
    
    private func updateNowPlayingInfo(_ current: (index: Int, waypoint: LocationDetail)?) {
        guard let current = current,
              let userLocation = userLocation ?? AppContext.shared.geolocationManager.location,
              let location = current.waypoint.source.closestLocation(from: userLocation, useEntranceIfAvailable: true) else {
            AudioSessionManager.removeNowPlayingInfo()
            return
        }
        
        let distance = location.distance(from: userLocation)
        let formattedDistance = LanguageFormatter.formattedDistance(from: distance)
        
        AudioSessionManager.setNowPlayingInfo(title: content.displayName,
                                              subtitle: current.waypoint.displayName,
                                              secondarySubtitle: formattedDistance)
    }
    
    private func findNearestIntersection() -> String? {
        guard let current = currentWaypoint?.waypoint.location else {
            return nil
        }
        
        guard let dataView = spatialDataContext.getDataView(for: current, searchDistance: IntersectionGenerator.arrivalDistance * 2) else {
            return nil
        }
        
        return dataView.intersections
            .map({ (intersection: $0, distance: $0.location.distance(from: current)) })
            .sorted(by: { $0.distance < $1.distance })
            .first(where: { $0.intersection.isMainIntersection(context: AppContext.secondaryRoadsContext) })?
            .intersection.key
    }
    
    private func saveState(finalize: Bool = false) {
        if let previous = lastSaveTime, !state.isFinal {
            state.totalTime += Date().timeIntervalSince(previous)
            lastSaveTime = Date()
        }
        
        if finalize {
            state.isFinal = true
        }
        
        NotificationCenter.default.post(name: Notification.Name.tourStateChanged, object: self)
    }
}
