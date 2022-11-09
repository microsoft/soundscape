//
//  IntersectionGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Combine
import CoreLocation

// MARK: Events

class IntersectionArrivalEvent: StateChangedEvent {
    let key: String
    let isRoundabout: Bool
    let heading: CLLocationDirection
    
    var  intersection: Intersection? {
        return SpatialDataCache.intersectionByKey(key)
    }
    
    init(_ intersectionKey: String, isRoundabout: Bool, heading: CLLocationDirection) {
        self.key = intersectionKey
        self.isRoundabout = isRoundabout
        self.heading = heading
    }
}

class IntersectionDepartureEvent: StateChangedEvent {
    let geocodedLocation: ReverseGeocoderResult
    
    init(_ geocodedLocation: ReverseGeocoderResult) {
        self.geocodedLocation = geocodedLocation
    }
}

// MARK: Notifications

extension Notification.Name {
    static let intersectionArrival = Notification.Name("GDAIntersectionArrival")
    static let intersectionDeparture = Notification.Name("GDAIntersectionDeparture")
}

class IntersectionGenerator: AutomaticGenerator {
    
    // MARK: - Constants
    
    /// The distance (in meters) in which we callout intersections.
    static let arrivalDistance = CLLocationDistance(35.0)
    
    /// The distance (in meters) in which we callout an intersection departure.
    static let departureDistance = CLLocationDistance(20.0)

    /// The time interval (in seconds) after a callout to invoke it again if needed
    static let timeoutBetweenSameCallout = TimeInterval(30.0)
    
    // MARK: - Notification Keys
    
    struct Keys {
        static let intersectionKey = "GDAIntersectionKey"
    }
    
    // MARK: - Events
    
    private var eventTypes: [StateChangedEvent.Type] = [
        LocationUpdatedEvent.self,
        IntersectionArrivalEvent.self,
        IntersectionDepartureEvent.self,
        GPXSimulationStartedEvent.self
    ]
    
    // MARK: - Update Filter
    
    private static let refreshDistance: CLLocationDistance = 5.0
    private static let refreshInterval: TimeInterval = 5.0
    private let updateFilter = LocationUpdateFilter(minTime: refreshInterval, minDistance: refreshDistance)
    
    /// Indicates if this automatic callout generator is allowed to interrupt other callouts
    /// that are already playing when it generates callouts. This should be used for
    /// automatic callout generators related to safety or critical information.
    var canInterrupt: Bool = true
    
    private unowned let owner: SoundscapeBehavior
    private unowned let spatialDataContext: SpatialDataProtocol
    private unowned let reverseGeocoder: ReverseGeocoder
    
    private let heading: Heading
    private var localCalloutHistory: [String: Date] = [:]
    private var currentRoundabout: Roundabout?
    
    private var cancellationTokens: [AnyCancellable] = []
    
    /// Tracks whether an interruption is currently taking place. Assumed to be false initially
    private var isAutomaticCalloutsInterrupted = false
    
    private var currentIntersectionKey: String?
    private var currentIntersection: Intersection? {
        if let key = currentIntersectionKey, let intersection = SpatialDataCache.intersectionByKey(key) {
            return intersection
        } else {
            // Failed to find intersection data... Remove corresponding key
            currentIntersectionKey = nil
            return nil
        }
    }
    
    init(_ owner: SoundscapeBehavior, geoManager: GeolocationManagerProtocol, data: SpatialDataProtocol, geocoder: ReverseGeocoder) {
        self.owner = owner
        heading = geoManager.heading(orderedBy: [.course])
        spatialDataContext = data
        reverseGeocoder = geocoder
        
        cancellationTokens.append(NotificationCenter.default.publisher(for: .automaticCalloutsDidChangeWithAudioState).sink { [weak self] _ in
            self?.isAutomaticCalloutsInterrupted = SettingsContext.shared.automaticCalloutsEnabled == false
        })
    }
    
    deinit {
        cancellationTokens.forEach { $0.cancel() }
        cancellationTokens.removeAll()
    }
    
    func respondsTo(_ event: StateChangedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func handle(event: StateChangedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let event as LocationUpdatedEvent:
            locationUpdated(event)
            return .noAction
            
        case is GPXSimulationStartedEvent:
            reset()
            return .noAction
            
        case let event as IntersectionArrivalEvent:
            let callout = IntersectionCallout(.intersection, event.key, event.isRoundabout, event.heading)
            
            GDATelemetry.track("callout", with: ["context": "intersection.arrival",
                                                 "type": callout.logCategory,
                                                 "activity": AppContext.shared.motionActivityContext.currentActivity.rawValue,
                                                 "audio.output": AppContext.shared.audioEngine.outputType])
            
            return .playCallouts(CalloutGroup([callout], action: .interruptAndClear, logContext: "intersections"))
            
        case let event as IntersectionDepartureEvent:
            let callout = event.geocodedLocation.buildCallout(origin: .intersection, sound: true, useClosestRoadIfAvailable: true)
            return .playCallouts(CalloutGroup([callout], action: .enqueue, logContext: "intersections"))
            
        default:
            return nil
        }
    }
    
    private func locationUpdated(_ event: LocationUpdatedEvent) {
        // Check if we can call out intersections
        guard let heading = heading.value else {
            clearCurrentData()
            return
        }
        
        checkIntersectionDeparture(event.location)
        
        guard isAutomaticCalloutsInterrupted == false else {
            // Do not clear intersection data
            // If the audio engine is disabled for an interruption, we want
            // to resume intersection callouts as expected after the interruption
            return
        }

        guard SettingsContext.shared.automaticCalloutsEnabled else {
            clearCurrentData()
            return
        }
        
        guard SettingsContext.shared.intersectionSenseEnabled else {
            clearCurrentData()
            return
        }

        // We don't callout intersections when a user is in a vehicle
        guard !AppContext.shared.motionActivityContext.isInVehicle else {
            clearCurrentData()
            return
        }
        
        guard updateFilter.shouldUpdate(location: event.location) else { return }
       
        guard let dataView = spatialDataContext.getDataView(for: event.location, searchDistance: IntersectionGenerator.arrivalDistance * 2) else {
            clearCurrentData()
            return
        }

        pruneCalloutHistory()
        
        let intersections = Intersection.filter(intersections: dataView.intersections,
                                                for: event.location,
                                                direction: heading,
                                                maxDistance: IntersectionGenerator.arrivalDistance,
                                                secondaryRoadsContext: AppContext.secondaryRoadsContext)
        
        handleNearbyIntersections(intersections, event.location)
    }
    
    private func checkIntersectionDeparture(_ location: CLLocation) {
        guard let currentIntersection = currentIntersection else {
            return
        }
        
        // Check that the user is traveling away from the current (last) intersection
        guard !location.isTraveling(towards: currentIntersection.location.coordinate, angularWindowRange: 180.0) else {
            return
        }
        
        // Check that the user has left the intersection's proximity
        let distance = currentIntersection.location.distance(from: location)
        guard distance > IntersectionGenerator.departureDistance else {
            return
        }
        
        GDLogIntersectionInfo("Distance to last called out intersection: \(String(format: "%.2f", distance))m")

        NotificationCenter.default.post(name: NSNotification.Name.intersectionDeparture,
                                        object: self,
                                        userInfo: [IntersectionGenerator.Keys.intersectionKey: currentIntersection.key])
        
        // We departed the intersection
        clearCurrentIntersection()
        
        guard SettingsContext.shared.automaticCalloutsEnabled else {
            GDLogIntersectionError("Skipping intersection departure... All callouts are disabled")
            return
        }
        
        guard SettingsContext.shared.intersectionSenseEnabled else {
            GDLogIntersectionError("Skipping intersection departure... Intersection callouts are disabled")
            return
        }
        
        guard let result = reverseGeocoder.reverseGeocode(location) else {
            return
        }
        
        GDLogIntersectionInfo("Generating intersection departure event")
        
        DispatchQueue.main.async {[weak self] in
            self?.owner.delegate?.process(IntersectionDepartureEvent(result))
        }
    }
    
    /// We currently support only one primary intersection. When we finish the callout for the
    /// intersection or the user has left it's proximity, we search for the next nearest one.
    private func handleNearbyIntersections(_ intersections: [Intersection], _ location: CLLocation) {
        // If no intersections in proximity
        guard let closestIntersection = intersections.first else {
            // No nearby intersections, only update the filter
            updateFilter.update(location: location)
            return
        }
        
        // If the current intersection is still in proximity, we don't callout a new one.
        if let currentIntersection = currentIntersection, intersections.contains(currentIntersection) {
            // Still in proximity to current intersection, only update the filter
            updateFilter.update(location: location)
            GDLogIntersectionWarn("Still in proximity with the current intersection")
            return
        }
        
        let intersection = Intersection.similarIntersectionWithMaxRoads(intersection: closestIntersection,
                                                                        intersections: intersections)
        
        // We are going to do the callout, so update the filter
        updateFilter.update(location: location)
        
        guard let heading = heading.value else {
            GDLogIntersectionWarn("Heading not valid")
            return
        }
        
        // If we reached an intersection that is not part of the current roundabout, clear the roundabout
        if let currentRoundabout = currentRoundabout, !currentRoundabout.contains(intersection) {
            clearCurrentRoundabout()
        }
        
        var isRoundabout = false
        
        // Check if the intersection should be announced as a roundabout
        // Note: We treat large roundabouts as intersection
        if currentRoundabout == nil, let roundabout = intersection.roundabout, !roundabout.isLarge {
            isRoundabout = true
            currentRoundabout = roundabout
        } else {
            guard let roadDirections = intersection.directions(relativeTo: heading), roadDirections.count > 0 else {
                GDLogIntersectionWarn("No road directions")
                return
            }
            
            let distinctRoadNames = roadDirections.map { $0.road.localizedName }.dropDuplicates()
            guard distinctRoadNames.count > 1 else {
                GDLogIntersectionWarn("Intersection is a road intersecting with itself.")
                return
            }
        }
 
        GDLogIntersectionInfo("Calling out intersection: \"\(intersection.localizedName)\", " +
            "distance: \(String(format: "%.2f", location.distance(from: intersection.location)))m, " +
            "bearing: \(String(format: "%.2f", location.bearing(to: intersection.location)))°, " +
            "presentationHeading: \(String(format: "%.2f", AppContext.shared.geolocationManager.presentationHeading.value ?? -1.0))°, " +
            "collectionHeading: \(String(format: "%.2f", AppContext.shared.geolocationManager.collectionHeading.value ?? -1.0))°, " +
            "id: \(intersection.key)")

        currentIntersectionKey = intersection.key
        
        // Add to callout history
        localCalloutHistory[intersection.key] = Date()
        
        NotificationCenter.default.post(name: NSNotification.Name.intersectionArrival,
                                        object: self,
                                        userInfo: [IntersectionGenerator.Keys.intersectionKey: intersection.key])
        
        DispatchQueue.main.async {[weak self] in
            guard let currentIntersectionKey = self?.currentIntersectionKey else {
                return
            }

            self?.owner.delegate?.process(IntersectionArrivalEvent(currentIntersectionKey, isRoundabout: isRoundabout, heading: heading))
        }
    }
    
    private func hasCalledOut(_ intersection: Intersection, within timeInterval: TimeInterval) -> Bool {
        for (key, date) in localCalloutHistory {
            if intersection.key == key && date > Date().addingTimeInterval(-timeInterval) {
                return true
            }
        }
        
        return false
    }
    
    /// Remove callout history items that expired
    private func pruneCalloutHistory() {
        guard !localCalloutHistory.isEmpty else { return }
        
        let now = Date()
        localCalloutHistory = localCalloutHistory.filter { (_, date) -> Bool in
            return now < date.addingTimeInterval(IntersectionGenerator.timeoutBetweenSameCallout)
        }
    }
    
    /// Release the nearest intersecion
    private func clearCurrentData() {
        clearCurrentIntersection()
        clearCurrentRoundabout()
    }
    
    /// Release the nearest intersecion
    private func clearCurrentIntersection() {
        currentIntersectionKey = nil
    }
    
    /// Release the roundabout intersecion
    private func clearCurrentRoundabout() {
        currentRoundabout = nil
    }
    
    func reset() {
        clearCurrentData()
        localCalloutHistory.removeAll()
    }
    
    /// Can be called by other `AutomaticGenerator`'s to signal that they have already generated
    /// a callout for a particular entity so no additional callouts should be generated.
    ///
    /// - Parameter id: ID/Key of the entity that was called out
    func cancelCalloutsForEntity(id: String) {
        // No-op currently
    }
}
