//
//  AutoCalloutGenerator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import AVFoundation.AVFAudio
import CoreLocation
import Combine

extension Notification.Name {
    static let automaticCalloutsDidChangeWithAudioState = Notification.Name("GDAAutomaticCalloutsDidChangeWithAudioState")
}

class ToggleAutoCalloutsEvent: UserInitiatedEvent {
    let playSound: Bool
    
    init(playSound: Bool) {
        self.playSound = playSound
    }
}

/// This event is created when the app state changes and a glyph needs to be played to indicate the state change
class GlyphEvent: StateChangedEvent {
    let glyph: StaticAudioEngineAsset
    let origin: CalloutOrigin
    
    init(_ glyph: StaticAudioEngineAsset, origin: CalloutOrigin = .system) {
        self.glyph = glyph
        self.origin = origin
    }
}

/// Event that is generated when a marker is added
class MarkerAddedEvent: UserInitiatedEvent {
    let markerId: String?
    
    init(_ id: String?) {
        markerId = id
    }
}

struct RegisterPrioritizedPOIs: StateChangedEvent {
    let distribution: EventDistribution = .broadcast
    let blockable: Bool = false
    
    let pois: [POI]
}

struct RemoveRegisteredPOIs: StateChangedEvent {
    let distribution: EventDistribution = .broadcast
    let blockable: Bool = false
}

/// A data structure private to this file that is used for tracking callouts that have been
/// recently performed for the purposes of preventing callouts from happening multiple times
/// for the same POI. Note that generic POI (e.g. crosswalks, gardens, bike parking, etc)
/// will match with other generic POIs with the same name so long as they are within the
/// appropriate proximity range of each other. This has the effect of reducing the number of
/// identical callouts a user will hear for generic POIs (e.g. users should hear a single
/// crosswalk callout at an intersection instead  of 4+).
private struct TrackedCallout {
    let callout: POICallout
    let category: SuperCategory
    let isGenericOSMPOI: Bool
    let trackingKey: String
    let time: Date
    
    init(_ callout: POICallout) {
        self.callout = callout
        time = Date()
        
        if let poi = callout.poi {
            isGenericOSMPOI = poi.isGenericOSMPOI
            trackingKey = poi.keyForTracking
            category = SuperCategory(rawValue: poi.superCategory) ?? SuperCategory.undefined
        } else {
            isGenericOSMPOI = false
            trackingKey = callout.key
            category = SuperCategory.undefined
        }
    }
    
    func matches(_ poi: POI, context: CalloutRangeContext) -> Bool {
        if poi.isGenericOSMPOI {
            if trackingKey == poi.keyForTracking, let trackedPOI = callout.poi {
                // If the POIs are both generic OSM POIs and are within the appropriate proximity range+ of each other, treat them as a match
                return trackedPOI.centroidLocation.distance(from: poi.centroidLocation) < category.proximityRange(context: context)
            }
            
            return false
        } else {
            return trackingKey == poi.keyForTracking
        }
    }
}

class AutoCalloutGenerator: AutomaticGenerator, ManualGenerator {
    
    // MARK: - Events
    
    private var eventTypes: [Event.Type] = [
        ToggleAutoCalloutsEvent.self,
        LocationUpdatedEvent.self,
        MarkerAddedEvent.self,
        GPXSimulationStartedEvent.self,
        GlyphEvent.self,
        RegisterPrioritizedPOIs.self,
        RemoveRegisteredPOIs.self
    ]
    
    // MARK: - Automatic Generator Properties
    
    let canInterrupt: Bool = false
    
    // MARK: - Private Constants
    
    private let inVehicleBeaconUpdateDistance: CLLocationDistance = 1000.0 // meters
    private let calloutDelay = 0.75
    
    // MARK: - Private Properties
    
    private unowned let settings: AutoCalloutSettingsProvider
    private unowned let spatialData: SpatialDataProtocol
    private unowned let revGeocoder: ReverseGeocoder
    private unowned let geo: GeolocationManagerProtocol
    
    private let locationUpdateFilter: LocationUpdateFilter
    private var poiUpdateFilter: MotionActivityUpdateFilter
    private var history: [TrackedCallout] = []
    private var categoryStates: [SuperCategory: Bool] = [:]
    private var cancellables: [AnyCancellable] = []
    private var didInterruptCallouts: Bool = false
    private var lastAnnouncedResult: ReverseGeocoderResult?
    private var prioritizedPOIs: [POI] = []
    
    private var spatialDataType: SpatialDataProtocol.Type {
        return type(of: spatialData)
    }
    
    // MARK: - Helper Properties
    
    private var calloutRangeContext: CalloutRangeContext {
        return spatialData.motionActivityContext.isInVehicle ? .automotive : .standard
    }
    
    /// Returns a filter predicate that appropriately filters POIs based on whether the user
    /// is currently driving or not. If they are driving then this predicate will filter to only
    /// include transit stops and landmarks. Otherwise, no filter predicate will be returned.
    private var motionContextFilterPredicate: FilterPredicate? {
        return SpatialDataView.filter(for: spatialData.motionActivityContext)
    }
    
    // MARK: - Initialization
    
    init(settings: AutoCalloutSettingsProvider, data: SpatialDataProtocol, geocoder: ReverseGeocoder, geo: GeolocationManagerProtocol) {
        self.settings = settings
        self.spatialData = data
        self.revGeocoder = geocoder
        self.geo = geo
        
        locationUpdateFilter = LocationUpdateFilter(minTime: 10.0, minDistance: 50.0)
        poiUpdateFilter = MotionActivityUpdateFilter(minTime: 5.0, minDistance: 5.0, motionActivity: data.motionActivityContext)
        
        configureCalloutCategories()
        
        cancellables.append(NotificationCenter.default.publisher(for: .autoCalloutCategorySenseChanged).sink { [unowned self] _ in
            self.configureCalloutCategories()
        })
        
        cancellables.append(NotificationCenter.default.publisher(for: .routeWaypointArrived).sink { [unowned self] notification in
            guard let id = notification.userInfo?[RouteGuidanceGenerator.Key.markerId] as? String else {
                return
            }
            
            guard let marker = SpatialDataCache.referenceEntityByKey(id) else {
                return
            }
            
            self.cancelCalloutsForEntity(id: marker.getPOI().key)
        })
        
        cancellables.append(NotificationCenter.default.publisher(for: .audioEngineStateChanged).sink { [unowned self] notification in
            guard let userInfo = notification.userInfo,
                  let stateValue = userInfo[AudioEngine.Keys.audioEngineStateKey] as? Int,
                  let state = AudioEngine.State(rawValue: stateValue) else {
                    return
            }
            
            if state == .stopped && self.settings.automaticCalloutsEnabled {
                GDLogAutoCalloutVerbose("Audio engine state changed <stopped> disabling automatic callouts")
                self.settings.automaticCalloutsEnabled = false
                didInterruptCallouts = true
            } else if state == .started && didInterruptCallouts {
                GDLogAutoCalloutVerbose("Audio engine state changed <started> enabling automatic callouts")
                self.settings.automaticCalloutsEnabled = true
                didInterruptCallouts = false
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .automaticCalloutsDidChangeWithAudioState, object: nil)
            }
        })
        
        settings.automaticCalloutsEnabled = true
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
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
        case let event as ToggleAutoCalloutsEvent:
            if settings.automaticCalloutsEnabled == true {
                // Disable automatic callouts
                settings.automaticCalloutsEnabled = false
                let callouts = CalloutGroup([GlyphCallout(.auto, .stopJourney)], action: .interruptAndClear, logContext: "automatic_callouts")
                return event.playSound ? .playCallouts(callouts) : nil
            }
            
            // Enable automatic callouts
            settings.automaticCalloutsEnabled = true
            let callouts = CalloutGroup([GlyphCallout(.auto, .startJourney)], action: .interruptAndClear, logContext: "automatic_callouts")
            return event.playSound ? .playCallouts(callouts) : nil
            
        case let event as MarkerAddedEvent:
            guard let id = event.markerId, let marker = SpatialDataCache.referenceEntityByKey(id) else {
                return nil
            }
        
            self.cancelCalloutsForEntity(id: marker.getPOI().key)
            
            guard !marker.isTemp else {
                return nil
            }
            
            let callout = StringCallout(.system, GDLocalizedString("markers.marker_created"))
            return .playCallouts(CalloutGroup([callout], logContext: "marker_added"))
            
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
            
        case let event as RegisterPrioritizedPOIs:
            GDLogInfo(.autoCallout, "Registered prioritized POIs for callout (count: \(event.pois.count))")
            prioritizedPOIs = event.pois
            return .noAction
            
        case is RemoveRegisteredPOIs:
            GDLogInfo(.autoCallout, "Removed registered prioritized POIs")
            prioritizedPOIs.removeAll()
            return .noAction
            
        case is GPXSimulationStartedEvent:
            history.removeAll()
            poiUpdateFilter.reset()
            return .noAction
            
        case let event as GlyphEvent:
            return .playCallouts(CalloutGroup([GlyphCallout(event.origin, event.glyph)], action: .enqueue, logContext: "glyphEvent"))
            
        default:
            return nil
        }
    }
    
    /// Temporarily blocks callouts for a particular POI
    /// - Parameter id: ID of the POI
    func cancelCalloutsForEntity(id: String) {
        guard SpatialDataCache.searchByKey(key: id) != nil else {
            return
        }
        
        history.append(TrackedCallout(POICallout(.auto, key: id, location: geo.location)))
    }
    
    // MARK: - Event Processing Methods
    private func locationUpdated(_ event: LocationUpdatedEvent) -> CalloutGroup? {
        guard settings.automaticCalloutsEnabled || !prioritizedPOIs.isEmpty else {
            GDLogAutoCalloutError("Skipping auto callouts. Callouts not enabled.")
            return nil
        }
        
        if !UIDeviceManager.isSimulator && geo.collectionHeading.value == nil {
            GDLogAutoCalloutInfo("Starting callouts while heading is unknown.")
        }
        
        if let locSense = buildCalloutForRoadSense(at: event.location) {
            // Log the location sense callout - this is only triggered when the user is in a car and they change roads
            GDLogAutoCalloutInfo("Generating road sense callout")
            let group = CalloutGroup([locSense], action: .enqueue, calloutDelay: calloutDelay, logContext: "automatic_callouts")
            group.delegate = self
            return group
        }
        
        // Get normal callouts for nearby POIs, for the destination, and for beacons
        let pois = getCalloutsForNearbyPOIs(nearby: event.location)
        
        // Make sure there are actually callouts
        guard pois.count > 0 else {
            return nil
        }
        
        // Update the LocationUpdateFilter object if we have things to call out
        poiUpdateFilter.update(location: event.location)
        
        if poiUpdateFilter.hasPrevious {
            GDLogAutoCalloutInfo("Nearby entities update filter passed (\(String(format: "%.2f", poiUpdateFilter.previousDistance))m, \(String(format: "%.2f", poiUpdateFilter.previousElapsed))s)")
        } else {
            GDLogAutoCalloutInfo("Nearby entities update filter passed (initial update)")
        }
        
        // Log the callouts
        GDLogAutoCalloutInfo("Generating \(pois.count) callouts")
        let group = CalloutGroup(pois, action: .enqueue, calloutDelay: calloutDelay, logContext: "automatic_callouts")
        group.delegate = self
        return group
    }
    
    // MARK: - Callout Lookup & Filtering
    
    /// Updates the most recent location and attempts to invoke Road Sense (previously called Location
    /// Sense). Road sense only runs when the user is in a vehicle. Location sense replaces the normal
    /// intersection callouts when in a vehicle (in order to limit the amount of content users are
    /// hearing - when driving, knowing the road you have turned onto is more useful than hearing the
    /// full layout of every intersection).
    ///
    /// - Parameter event: an event that is sent when the location updates
    private func buildCalloutForRoadSense(at location: CLLocation) -> CalloutProtocol? {
        guard locationUpdateFilter.shouldUpdate(location: location) else {
            return nil
        }
        
        // While in a vehicle, the intersection callouts are disabled, and we use the location sense callouts.
        guard settings.automaticCalloutsEnabled, settings.mobilitySenseEnabled, spatialData.motionActivityContext.isInVehicle else {
            return nil
        }
        
        GDLogAutoCalloutVerbose("Trying location sense. User is in vehicle.")
        
        // Update the update filter
        
        locationUpdateFilter.update(location: location)
        
        if locationUpdateFilter.hasPrevious {
            GDLogLocationInfo("Update Filter Passed (\(self.locationUpdateFilter.previousDistance) m, \(self.locationUpdateFilter.previousElapsed) sec)")
        } else {
            GDLogLocationInfo("Update Filter Passed (initial update)")
        }
        
        // Reverse geocode the current location
        
        guard let dataView = spatialData.getDataView(for: location, searchDistance: spatialDataType.initialPOISearchDistance) else {
            return nil
        }
        
        GDLogGeocoderInfo("Reverse Geocode - from location updated (\(location.description))")
        
        let result = revGeocoder.reverseGeocode(location, data: dataView, heading: geo.collectionHeading)
        
        // Make sure the location changed
        
        // When a user is in an automotive state, but is not alonside a road, such as a train ride,
        // the `GenericGeocoderResult` type is used.
        if let genericGeocoderResult = result as? GenericGeocoderResult {
            guard let poi = genericGeocoderResult.poi else {
                GDLogAutoCalloutVerbose("Skipping location sense. GenericGeocoderResult error: not a valid landmark POI.")
                return nil
            }
            
            let category = SuperCategory(rawValue: poi.superCategory) ?? SuperCategory.undefined
            
            // We make sure the geocoded result has a POI that is a landmark or a marker
            guard category == SuperCategory.landmarks || SpatialDataCache.referenceEntityByEntityKey(poi.key) != nil else {
                GDLogAutoCalloutVerbose("Skipping location sense. GenericGeocoderResult error: POI is not a landmark or a marker. ")
                return nil
            }
            
            if let lastGenericGeocoderResult = lastAnnouncedResult as? GenericGeocoderResult {
                guard let name = genericGeocoderResult.poi?.localizedName, let lastName = lastGenericGeocoderResult.poi?.localizedName, name != lastName else {
                    GDLogAutoCalloutVerbose("Skipping location sense. GenericGeocoderResult error: POI name is similar to the last result.")
                    return nil
                }
            }
        } else {
            guard lastAnnouncedResult?.isSignificantlyDifferent(result) ?? true else {
                GDLogAutoCalloutVerbose("Skipping location sense. Location not changed significantly.")
                return nil
            }
        }
        
        lastAnnouncedResult = result
        return result.buildCallout(origin: .auto, sound: false, useClosestRoadIfAvailable: false)
    }
    
    /// Gets an array of nearby POIs that should be called out as normal automatic
    /// callouts. This method takes into account the current callout settings, and
    /// the last time and location each POI was called out at (to prevent duplicate
    /// callouts)
    ///
    /// - Parameter location: The user's current location
    /// - Returns: Callouts for nearby POIs
    private func getCalloutsForNearbyPOIs(nearby location: CLLocation) -> [POICallout] {
        guard poiUpdateFilter.shouldUpdate(location: location) else {
            return []
        }
        
        GDLogVerbose(.autoCallout, "Checking for POIs to callout")
        
        let context = calloutRangeContext
        
        guard let dataView = spatialData.getDataView(for: location, searchDistance: context.searchDistance) else {
            let callouts = filterAnnounceablePOIs(prioritizedPOIs, near: location, context: context) {
                return POICallout(.auto, poi: $0, location: location)
            }
            
            if callouts.isEmpty {
                GDLogInfo(.autoCallout, "Skipping POI auto callouts. Unable to get spatial data view.")
            }
            
            return callouts
        }
        
        // Cleanup invalid POIs
        cleanupHistory(location: location, context: context)
        
        GDLogVerbose(.autoCallout, "Searching for nearest POIs... (Limited to 10 nearest)")
        
        // Get the POIs sorted by distance, and filtered for duplicate names
        let prioritizedCallouts = filterAnnounceablePOIs(prioritizedPOIs, near: location, context: context) {
            return POICallout(.auto, poi: $0, location: location)
        }
        
        let defaultCallouts = !settings.automaticCalloutsEnabled ? [] : filterAnnounceablePOIs(dataView.pois, near: location, context: context) {
            return POICallout(.auto, key: $0.key, location: location)
        }

        if defaultCallouts.count + prioritizedCallouts.count == 0 {
            // There was nothing to call out, so update the filter
            poiUpdateFilter.update(location: location)
        }
        
        return prioritizedCallouts + defaultCallouts
    }
    
    private func filterAnnounceablePOIs(_ pois: [POI], near location: CLLocation, context: CalloutRangeContext, calloutBuilder: (POI) -> POICallout) -> [POICallout] {
        return pois.sorted(by: Sort.distance(origin: location), // Sort POIs by distance from the user's location
                           filteredBy: motionContextFilterPredicate, // Limit to transit and landmarks when in a car
                           maxLength: 10)
                   .filter { poi in
                       // Skip this POI if it's sense is turned off and it's not a marker
                       let senseIsOn = categoryStates[poi.category, default: false]
                       guard senseIsOn || SpatialDataCache.referenceEntityByEntityKey(poi.key) != nil else {
                           // Filter callout because category is disabled
                           return false
                       }
                       
                       // Don't do regular automatic callouts for POIs with the audio beacon set on them
                       if spatialData.destinationManager.isDestination(key: poi.key) {
                           return false
                       }
                       
                       // If the POI has been called out too recently or too close to the user's current location,
                       // skip it...
                       guard !history.contains(where: { $0.matches(poi, context: context) }) else {
                           return false
                       }
                       
                       let distance = poi.distanceToClosestLocation(from: location)
                       let triggerRange = poi.category.triggerRange(context: context)
                       return distance <= triggerRange
                   }
                   .reduce(into: [String: POI]()) { uniquelyNamedPOIs, poi in
                       if uniquelyNamedPOIs[poi.keyForTracking] == nil {
                           uniquelyNamedPOIs[poi.keyForTracking] = poi
                       }
                   }
                   .map { (unique) -> POICallout in
                       let callout = calloutBuilder(unique.value)
                       let range = unique.value.category.triggerRange(context: context).roundToDecimalPlaces(2)
                       let distance = unique.value.distanceToClosestLocation(from: location).roundToDecimalPlaces(2)
                       GDLogVerbose(.autoCallout, "\t[ELIGIBLE]: \(callout.debugDescription), \(callout.key)\(unique.value.isGenericOSMPOI ? " [" + unique.value.keyForTracking + "]" : "" ), \(distance) meters [trigger: \(range)m]")
                       
                       history.append(TrackedCallout(callout))
                       
                       return callout
                   }
    }
    
    // MARK: - Helper Methods
    
    private func cleanupHistory(location: CLLocation, context: CalloutRangeContext) {
        // If the minimum time interval has passed OR the distance to the tracked POI is greater
        // than the proximity range for the POI's category, remove the POI from the callout tracking
        history.removeAll(where: { tracked in
            // Remove callout if the minimum time interval has elapsed
            if Date().timeIntervalSince(tracked.time) > automaticCalloutTimeInterval(for: tracked.callout.poi) {
                return true
            }
            
            // We should always have an underlying POI, so if we don't, remove this item from the history
            guard let poi = tracked.callout.poi else {
                return true
            }
            
            // Remove callout if the user has left the proximity range of the POI (respecting the motion activity)
            let range = tracked.category.proximityRange(context: context)
            return poi.distanceToClosestLocation(from: location, useEntranceIfAvailable: false) > range
        })
    }
    
    private func automaticCalloutTimeInterval(for poi: POI?) -> TimeInterval {
        return 60.0 // seconds
    }
    
    private func configureCalloutCategories() {
        // Update the current callout settings
        categoryStates[.places] = settings.placeSenseEnabled
        categoryStates[.information] = settings.informationSenseEnabled
        categoryStates[.mobility] = settings.mobilitySenseEnabled
        categoryStates[.safety] = settings.safetySenseEnabled
        categoryStates[.landmarks] = settings.landmarkSenseEnabled
        categoryStates[.authoredActivity] = true
    }
}

extension AutoCalloutGenerator: CalloutGroupDelegate {
    func isCalloutWithinRegionToLive(_ callout: CalloutProtocol) -> Bool {
        // Region to live only matters for POICallouts
        guard let callout = callout as? POICalloutProtocol else {
            return true
        }
        
        // Only POIs currently support a region-to-live (callouts without a POI should always return true)
        guard let poi = callout.poi, let location = geo.location else {
            return true
        }
        
        let category = SuperCategory(rawValue: poi.superCategory) ?? SuperCategory.undefined
        
        // Bluetooth beacons are always in the region to live
        guard category != .beacons else {
            return true
        }
                
        let triggerRange = category.triggerRange(context: calloutRangeContext)
        if triggerRange < poi.distanceToClosestLocation(from: location) {
            return false
        }
        
        return true
    }
    
    func calloutSkipped(_ callout: CalloutProtocol) {
        calloutFinished(callout, completed: false)
    }
    
    func calloutStarting(_ callout: CalloutProtocol) {
        // no-op
    }
    
    func calloutFinished(_ callout: CalloutProtocol, completed: Bool) {
        guard let callout = callout as? POICallout else {
            return
        }
        
        // If the callout was interrupted and not completed, remove it from the log so that
        // it can have another chance to be called out in subsequent checks for callouts.
        if !completed {
            history.removeAll(where: { $0.callout.id == callout.id })
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

// MARK: Private POI Extensions

private extension POI {
    var category: SuperCategory {
        return SuperCategory(rawValue: self.superCategory) ?? SuperCategory.undefined
    }
    
    var isGenericOSMPOI: Bool {
        if let osmPOI = self as? GDASpatialDataResultEntity, osmPOI.nameTagLocalizationKey != nil {
            return true
        }
        
        return false
    }
    
    var keyForTracking: String {
        // Use the POI's key for tracking in the lastCallout dictionaries, unless the POI is a generic OSM
        // POI like a crossing, in which case, use the POI's localized name. This will prevent repeating
        // generic callouts like "Crossing" multiple times in a row
        if let osmPOI = self as? GDASpatialDataResultEntity, let locKey = osmPOI.nameTagLocalizationKey {
            return locKey
        } else {
            return key
        }
    }
    
    var debugDescription: String {
        if let marker = SpatialDataCache.referenceEntityByEntityKey(key) {
            if marker.name.isEmpty {
                // Use a default name
                return GDLocalizedString("markers.generic_name")
            } else {
                let containsMarkerInName = marker.name.lowercasedWithAppLocale().contains(GDLocalizedString("markers.generic_name").lowercasedWithAppLocale())
                
                if containsMarkerInName || marker.isTemp {
                    return marker.name
                } else {
                    return GDLocalizedString("markers.marker_with_name", marker.name)
                }
            }
        } else if let poi = SpatialDataCache.searchByKey(key: key) {
            if poi.localizedName.isEmpty {
                // Use a default name
                return GDLocalizedString("location")
            } else {
                return poi.localizedName
            }
        }
        
        return ""
    }
}
