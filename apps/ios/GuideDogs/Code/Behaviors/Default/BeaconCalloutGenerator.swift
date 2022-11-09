//
//  BeaconCalloutGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation.AVFAudio
import CoreLocation
import Combine

struct BeaconCalloutEvent: UserInitiatedEvent {
    let beaconId: String
    let logContext: String
}

struct BeaconChangedEvent: UserInitiatedEvent {
    let audioEnabled: Bool
    let markerId: String?
    
    init(id: String?, audioEnabled: Bool) {
        self.audioEnabled = audioEnabled
        markerId = id
    }
}

struct BeaconGeofenceTriggeredEvent: StateChangedEvent {
    var type: EventType = .stateChanged
    
    let markerId: String?
    let didEnter: Bool
    let beaconIsEnabled: Bool
    let beaconWasEnabled: Bool
    let location: CLLocation
    
    init(beaconId: String, didEnter: Bool, beaconIsEnabled: Bool, beaconWasEnabled: Bool, location: CLLocation) {
        self.markerId = beaconId
        self.didEnter = didEnter
        self.beaconIsEnabled = beaconIsEnabled
        self.beaconWasEnabled = beaconWasEnabled
        self.location = location
    }
}

class BeaconCalloutGenerator: AutomaticGenerator, ManualGenerator {
    
    // MARK: - Events
    
    private var eventTypes: [Event.Type] = [
        LocationUpdatedEvent.self,
        BeaconCalloutEvent.self,
        BeaconChangedEvent.self,
        BeaconGeofenceTriggeredEvent.self,
        GPXSimulationStartedEvent.self
    ]
    
    // MARK: - Automatic Generator Properties
    
    let canInterrupt: Bool = false
    
    // MARK: - Private Constants
    
    private let inVehicleBeaconUpdateDistance: CLLocationDistance = 1000.0 // meters
    private let calloutDelay: TimeInterval = 0.75
    
    // MARK: - Private Properties
    
    private unowned let spatialData: SpatialDataProtocol
    private unowned let geo: GeolocationManagerProtocol
    private unowned let settings: AutoCalloutSettingsProvider
    
    private var userLocation: CLLocation?
    private var destinationKey: String?
    private var beaconUpdateFilter: MotionActivityUpdateFilter
    
    // MARK: - Initialization
    
    init(data: SpatialDataProtocol, geo: GeolocationManagerProtocol, settings: AutoCalloutSettingsProvider) {
        self.spatialData = data
        self.geo = geo
        self.settings = settings
        
        beaconUpdateFilter = MotionActivityUpdateFilter(minTime: 5.0, minDistance: 50.0, motionActivity: data.motionActivityContext)
        
        destinationKey = data.destinationManager.destinationKey
        configureDestinationUpdates()
    }
    
    // MARK: - AutomaticGenerator & ManualGenerator Methods
    
    func respondsTo(_ event: StateChangedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func respondsTo(_ event: UserInitiatedEvent) -> Bool {
        return eventTypes.contains { $0 == type(of: event) }
    }
    
    func handle(event: UserInitiatedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let event as BeaconCalloutEvent:
            return .playCallouts(CalloutGroup([DestinationCallout(.auto, event.beaconId)], action: .interruptAndClear, logContext: event.logContext))
            
        case let event as BeaconChangedEvent:
            guard settings.automaticCalloutsEnabled else {
                GDLogAutoCalloutError("Skipping beacon auto callouts. Callouts not enabled.")
                return .noAction
            }
            
            guard let callouts = beaconChanged(event) else {
                return .noAction
            }
            
            return .playCallouts(callouts)
            
        default:
            return nil
        }
    }
    
    func handle(event: StateChangedEvent, verbosity: Verbosity) -> HandledEventAction? {
        switch event {
        case let event as LocationUpdatedEvent:
            guard let callouts = locationUpdated(event) else {
                return .noAction
            }
            
            return .playCallouts(callouts)
            
        case is GPXSimulationStartedEvent:
            beaconUpdateFilter.reset()
            return .noAction
            
        case let event as BeaconGeofenceTriggeredEvent:
            guard let callouts = beaconGeofenceTriggered(event) else {
                return .noAction
            }
            
            return .playCallouts(callouts)
                        
        default:
            return nil
        }
    }
    
    /// Temporarily blocks callouts for a particular POI
    /// - Parameter id: ID of the POI
    func cancelCalloutsForEntity(id: String) {
        // No-op: This generator does not support callout cancellation
    }
    
    // MARK: - Event Processing Methods
    private func locationUpdated(_ event: LocationUpdatedEvent) -> CalloutGroup? {
        // Save the updated location regardless of whether we do any callouts or not
        userLocation = event.location
        
        guard settings.automaticCalloutsEnabled else {
            GDLogAutoCalloutError("Skipping beacon callouts. Automatic callouts not enabled.")
            return nil
        }
        
        if !UIDeviceManager.isSimulator && geo.collectionHeading.value == nil {
            GDLogAutoCalloutInfo("Starting callouts while heading is unknown.")
        }
        
        // Get normal callouts for nearby POIs, for the destination, and for beacons
        let destinations = getCalloutsForBeacon(nearby: event.location, origin: .auto) ?? []
        
        // Make sure there are actually callouts
        guard destinations.count > 0 else {
            return nil
        }
        
        // Update the LocationUpdateFilter object for the destination
        beaconUpdateFilter.update(location: event.location)
        
        if beaconUpdateFilter.hasPrevious {
            GDLogAutoCalloutInfo("Destination update filter passed (\(beaconUpdateFilter.previousDistance) m, \(beaconUpdateFilter.previousElapsed) sec")
        } else {
            GDLogAutoCalloutInfo("Destination update filter passed (initial update)")
        }
        
        // Log the callouts
        GDLogAutoCalloutInfo("Generating \(destinations.count) callouts")
        let group = CalloutGroup(destinations, action: .enqueue, calloutDelay: calloutDelay, logContext: "automatic_callouts")
        group.delegate = self
        return group
    }
    
    private func beaconChanged(_ event: BeaconChangedEvent) -> CalloutGroup? {
        // Similar to location updates, always keep track of the current destination key regardless
        // of whether destination callouts are currently on or not (this allows us to start doing
        // destination callouts as soon as they are turned on without reaching into global state to
        // look up the destination key).
        guard event.markerId != nil else {
            destinationKey = nil
            return nil
        }
        
        destinationKey = event.markerId
        
        guard let location = userLocation else {
            return nil
        }
        
        guard let destinations = getCalloutsForBeacon(nearby: location, origin: .beaconChanged) else {
            return nil
        }
        
        // Update the LocationUpdateFilter object for the destination
        guard destinations.count > 0 else {
            return nil
        }
        
        beaconUpdateFilter.update(location: location)
        
        if beaconUpdateFilter.hasPrevious {
            GDLogAutoCalloutInfo("Destination update filter passed (\(beaconUpdateFilter.previousDistance) m, \(beaconUpdateFilter.previousElapsed) sec")
        } else {
            GDLogAutoCalloutInfo("Destination update filter passed (initial update)")
        }
        
        // Log the callouts
        GDLogAutoCalloutInfo("Generating \(destinations.count) beacon callouts (beacon changed)")
        let group = CalloutGroup(destinations, action: .enqueue, calloutDelay: calloutDelay, logContext: "automatic_callouts")
        group.delegate = self
        return group
    }
    
    private func beaconGeofenceTriggered(_ event: BeaconGeofenceTriggeredEvent) -> CalloutGroup? {
        userLocation = event.location
        
        guard settings.automaticCalloutsEnabled else {
            GDLogAutoCalloutError("Skipping beacon geofence callouts. Automatic callouts not enabled.")
            return nil
        }
        
        let causedAudioDisabled = event.beaconWasEnabled && !event.beaconIsEnabled
        guard let destinations = getCalloutsForBeacon(nearby: event.location, origin: .beaconGeofence, causedAudioDisable: causedAudioDisabled) else {
            return nil
        }
        
        // Update the LocationUpdateFilter object for the destination
        guard destinations.count > 0 else {
            return nil
        }
        
        beaconUpdateFilter.update(location: event.location)
        
        if beaconUpdateFilter.hasPrevious {
            GDLogAutoCalloutInfo("Destination update filter passed (\(beaconUpdateFilter.previousDistance) m, \(beaconUpdateFilter.previousElapsed) sec")
        } else {
            GDLogAutoCalloutInfo("Destination update filter passed (initial update)")
        }
        
        // Log the callouts
        GDLogAutoCalloutInfo("Generating \(destinations.count) beacon callouts (beacon geofence entered)")
        let group = CalloutGroup(destinations, action: .enqueue, calloutDelay: calloutDelay, logContext: "automatic_callouts")
        group.delegate = self
        return group
    }
    
    private func getCalloutsForBeacon(nearby location: CLLocation, origin: CalloutOrigin, causedAudioDisable: Bool = false) -> [DestinationCallout]? {
        // Check if destination callouts are enabled
        guard settings.destinationSenseEnabled else {
            GDLogAutoCalloutInfo("Skipping beacon auto callouts. Beacon callouts are not enabled.")
            return nil
        }
        
        // Check if a destination is currently set
        guard let key = destinationKey else {
            return nil
        }
        
        // If the callout is not coming from .auto, there are no additional checks to make
        if origin == .auto, let destination = spatialData.destinationManager.destination {
            // Check the update filter (if this callout is coming from auto callouts)
            guard beaconUpdateFilter.shouldUpdate(location: location) else {
                return nil
            }
            
            // Don't do a location update for the destination if we have already entered the immediate vicinity
            guard destination.distanceToClosestLocation(from: location) > DestinationManager.EnterImmediateVicinityDistance else {
                return nil
            }
        }
        
        GDLogAutoCalloutVerbose("Preparing for beacon callout")
        
        // Configure destination updates for the new location
        configureDestinationUpdates()
        
        // Build the destination callout
        return [DestinationCallout(origin, key, causedAudioDisable)]
    }
    
    // MARK: - Helper Methods
    
    private func configureDestinationUpdates() {
        guard let location = userLocation else { return }
        guard let poi = spatialData.destinationManager.destination?.getPOI() else { return }
        
        let distance = poi.distanceToClosestLocation(from: location)
        
        // Per feedback: increase the time interval for destination callouts when in-vehicle,
        // but have more frequent updates when inside a 1km radius.
        if distance < inVehicleBeaconUpdateDistance {
            beaconUpdateFilter.inVehicleTimeIntervalMultiplier = 5
        } else {
            beaconUpdateFilter.inVehicleTimeIntervalMultiplier = 10
        }
    }
}

extension BeaconCalloutGenerator: CalloutGroupDelegate {
    func isCalloutWithinRegionToLive(_ callout: CalloutProtocol) -> Bool {
        return true
    }
    
    func calloutSkipped(_ callout: CalloutProtocol) {
        calloutFinished(callout, completed: false)
    }
    
    func calloutStarting(_ callout: CalloutProtocol) {
        // No-op
    }
    
    func calloutFinished(_ callout: CalloutProtocol, completed: Bool) {
        // If the callout was interrupted and not completed, remove it from the log so that
        // it can have another chance to be called out in subsequent checks for callouts.
        if !completed {
            GDLogVerbose(.autoCallout, "Skipped callout for \(callout.debugDescription)")
        } else {
            GDLogVerbose(.autoCallout, "Completed callout for \(callout.debugDescription)")
        }
    }
    
    func calloutsSkipped(for group: CalloutGroup) {
        GDLogVerbose(.autoCallout, "Callout group skipped (\(group.id))")
    }
    
    func calloutsStarted(for group: CalloutGroup) {
        GDLogVerbose(.autoCallout, "Starting callout group (\(group.id))")
    }
    
    func calloutsCompleted(for group: CalloutGroup, finished: Bool) {
        GDLogVerbose(.autoCallout, "Finished callout group (\(group.id))")
    }
}
