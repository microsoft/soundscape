//
//  DestinationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import CoreLocation

extension Notification.Name {
    static let destinationChanged = Notification.Name("GDADestinationChanged")
    static let destinationAudioChanged = Notification.Name("GDADestinationAudioChanged")
    static let enableDestinationGeofence = Notification.Name("GDAEnableDestinationGeofence")
    static let disableDestinationGeofence = Notification.Name("GDADisableDestinationGeofence")
    static let destinationGeofenceDidTrigger = Notification.Name("GDADestinationGeofenceDidTrigger")
    static let beaconInBoundsDidChange = Notification.Name("GDABeaconInBoundsDidChange")
}

enum DestinationManagerError: Error {
    case referenceEntityDoesNotExist
}

class DestinationManager: DestinationManagerProtocol {
    
    static let LeaveImmediateVicinityDistance: CLLocationDistance = 30.0
    static let EnterImmediateVicinityDistance: CLLocationDistance = 15.0
    
    // MARK: Notification Keys
    
    struct Keys {
        static let isAudioEnabled = "GDADestinationAudioIsEnabled"
        static let wasAudioEnabled = "GDADestinationAudioWasEnabled"
        static let geofenceDidEnter = "GDADestinationGeofenceDidEnterKey"
        static let destinationKey = "DestinationReferenceKey"
        static let isBeaconInBounds = "IsBeaconInBounds"
    }
    
    // MARK: Args for starting beacons
    
    private struct BeaconArgs {
        let loc: CLLocation
        let heading: Heading
        var startMelody: Bool
        var endMelody: Bool
    }
    
    // MARK: Properties
    
    private(set) var destinationKey: String? {
        get {
            return UserDefaults.standard.value(forKey: DestinationManager.Keys.destinationKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DestinationManager.Keys.destinationKey)
        }
    }
    
    var isDestinationSet: Bool {
        return destinationKey != nil
    }
    
    var destination: ReferenceEntity? {
        guard let destinationKey = self.destinationKey else {
            return nil
        }
        
        return SpatialDataCache.referenceEntityByKey(destinationKey)
    }

    // All continuous audio should be disabled on launch
    var isAudioEnabled: Bool {
        return beaconPlayerId != nil || hapticBeacon != nil
    }
    
    private var beaconClosestLocation: CLLocation?
    private var temporaryBeaconClosestLocation: CLLocation?
    private var isGeofenceEnabled: Bool = true
    private var isWithinGeofence: Bool = false
    
    private weak var audioEngine: AudioEngineProtocol!
    
    private var finishBeaconPlayerOnRemove: Bool = false
    private var _beaconPlayerId: AudioPlayerIdentifier? {
        didSet {
            // Make sure there was a previous value and it doesn't equal the new value
            guard let oldID = oldValue, oldID != _beaconPlayerId else {
                return
            }
            
            if destinationKey != nil && !finishBeaconPlayerOnRemove {
                // The beacon was just muted - stop the audio without the end melody
                audioEngine.stop(oldID)
            } else {
                // Otherwise, the beacon was removed. Allow the end melody to play if one exists
                audioEngine.finish(dynamicPlayerId: oldID)
            }
            
            if _beaconPlayerId == nil {
                isCurrentBeaconAsyncFinishable = false
            }
        }
    }
    
    var beaconPlayerId: AudioPlayerIdentifier? {
        get {
            return _beaconPlayerId ?? hapticBeacon?.beacon
        }
    }
    
    private(set) var proximityBeaconPlayerId: AudioPlayerIdentifier? {
        didSet {
            // Make sure there was a previous value and it doesn't equal the new value
            guard let oldID = oldValue, oldID != proximityBeaconPlayerId else {
                return
            }
            
            if destinationKey != nil {
                // The beacon was just muted - stop the audio without the end melody
                audioEngine.stop(oldID)
            } else {
                // Otherwise, the beacon was removed. Allow the end melody to play if one exists
                audioEngine.finish(dynamicPlayerId: oldID)
            }
        }
    }
    
    private var hapticBeacon: HapticBeacon?
    
    private var didInterruptBeacon = false
    private let collectionHeading: Heading
    
    private(set) var isBeaconInBounds: Bool = false {
        didSet {
            guard oldValue != isBeaconInBounds else {
                return
            }
            
            let name = Notification.Name.beaconInBoundsDidChange
            
            let userInfo = [
                Keys.isBeaconInBounds: isBeaconInBounds
            ]
            
            NotificationCenter.default.post(name: name, object: self, userInfo: userInfo)
        }
    }
    
    private(set) var isCurrentBeaconAsyncFinishable: Bool = false
    
    private var appDidInitialize = false

    // MARK: Initialization
    
    init(userLocation: CLLocation? = nil, audioEngine engine: AudioEngineProtocol, collectionHeading: Heading) {
        self.collectionHeading = collectionHeading
        
        audioEngine = engine
        
        // Verify that destination exists
        if destinationKey != nil && destination == nil {
            destinationKey = nil
        }
        
        // If the current destination is temp and doesn't have a name, remove it (it was from the scavenger hunt)
        if let destination = destination, destination.isTemp, destination.name == RouteGuidance.name {
            do {
                try clearDestination(logContext: "startup")
            } catch {
                GDLogAppError("Failed to clear temp/unnamed beacon on startup")
            }
        }
        
        if let poi = destination?.getPOI(), let userLocation = userLocation {
            // Determine if user is within geofence
            isWithinGeofence = isLocationWithinGeofence(origin: poi, location: userLocation)
        }
        
        // Listen for updates to `collectionHeading`
        collectionHeading.onHeadingDidUpdate { [weak self] (_ heading: HeadingValue?) in
            guard let `self` = self else {
                return
            }
            
            // Don't directly access the beacon POI - we don't want to have to retrieve it from
            // the database at frequency we receive heading updates. Instead, just check if there is
            // currently a beacon playing, and then only update the `isBeaconInBounds` flag is there is.
            guard self.beaconPlayerId != nil else {
                return
            }
            
            if let heading = heading?.value {
                self.isBeaconInBounds = self.isBeaconInBounds(with: heading)
            } else {
                self.isBeaconInBounds = false
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onLocationUpdated), name: Notification.Name.locationUpdated, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onEnableGeofence(_:)), name: NSNotification.Name.enableDestinationGeofence, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDisableGeofence(_:)), name: NSNotification.Name.disableDestinationGeofence, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAudioEngineStateChanged(_:)), name: NSNotification.Name.audioEngineStateChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAppDidInitialize(_:)), name: NSNotification.Name.appDidInitialize, object: nil)
    }
    
    // MARK: Manage Destination Methods
    
    func isDestination(key: String) -> Bool {
        guard destinationKey == key || destination?.entityKey == key else {
            // Return false if the destination isn't set or the entityKey doesn't match the destination
            return false
        }
        
        return true
    }
    
    /// Sets the provided ReferenceEntity as the current destination.
    ///
    /// - Parameters:
    ///   - referenceID: ID of the ReferenceEntity to set as the destination
    ///   - enableAudio: Flag indicating if the beacon should be turned on automatically for the destination
    ///   - userLocation: The user's current location
    ///   - logContext: The context of the call that will be passed to the telemetry service
    /// - Throws: If the destination cannot be set
    func setDestination(referenceID: String, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws {
        guard let entity = SpatialDataCache.referenceEntityByKey(referenceID) else {
            throw DestinationManagerError.referenceEntityDoesNotExist
        }
        
        destinationKey = referenceID
        isGeofenceEnabled = true
        isWithinGeofence = false
        
        if let userLoc = userLocation ?? AppContext.shared.geolocationManager.location {
            updateBeaconClosestLocation(for: userLoc)
        }
        
        if let heading = collectionHeading.value {
            isBeaconInBounds = isBeaconInBounds(with: heading)
        } else {
            isBeaconInBounds = false
        }
        
        // If user location is known, is user within geofence?
        if let userLocation = userLocation {
            isWithinGeofence = isLocationWithinGeofence(origin: entity.getPOI(), location: userLocation)
        }
        
        // Start audio if enabled and user is not within geofence
        if let location = userLocation, enableAudio, !isWithinGeofence {
            enableDestinationAudio(userLocation: location)
        } else if isAudioEnabled {
            // If not, and the audio is already on, turn it off (e.g. user is within the geofence of the new beacon already)
            disableDestinationAudio()
        }
        
        try entity.updateLastSelectedDate()
        
        notifyDestinationChanged(id: referenceID)
        
        if FirstUseExperience.didComplete(.oobe) {
            updateNowPlayingDisplay(for: userLocation)
            GDATelemetry.helper?.beaconCountSet += 1
        }
        
        // Log the destination change and notify the rest of the app
        GDATelemetry.track("beacon.added", with: (logContext != nil) ? ["context": logContext!] : nil)
    }
    
    /// Creates a temporary reference entity for the location specified and sets it as the current
    /// destination. When this destination is later cleared, the temporary reference entity will be removed.
    ///
    /// - Parameters:
    ///   - location: Generic location to set as a destination
    ///   - address: Estimated address of the generic location
    ///   - enableAudio: Flag indicating if the beacon should be turned on automatically for the destination
    ///   - userLocation: The user's current location
    ///   - logSource: The context of the call that will be passed to the telemetry service
    /// - Returns: The id of the reference entity set as the destination
    /// - Throws: If the temp reference entity cannot be created or if destination cannot be set
    @discardableResult
    func setDestination(location: CLLocation, address: String?, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws -> String {
        // The generic location cannot already exist if this method is called, so go ahead and create one
        let genericLoc: GenericLocation = GenericLocation(lat: location.coordinate.latitude,
                                                          lon: location.coordinate.longitude,
                                                          name: address == nil ? GDLocalizedString("beacon.audio_beacon") : GDLocalizationUnnecessary(""))
        
        return try setDestination(location: genericLoc, address: address, enableAudio: enableAudio, userLocation: userLocation, logContext: logContext)
    }
    
    @discardableResult
    func setDestination(location: GenericLocation, address: String?, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws -> String {
        // If the reference entity already exists, just set the destination to that
        if let ref = SpatialDataCache.referenceEntityByGenericLocation(location) {
            try setDestination(referenceID: ref.id, enableAudio: enableAudio, userLocation: userLocation, logContext: logContext)
            
            return ref.id
        }
        
        let refID = try ReferenceEntity.add(location: location, estimatedAddress: address, temporary: true)
        
        // Set the newly created generic location as the destination
        try setDestination(referenceID: refID, enableAudio: enableAudio, userLocation: userLocation, logContext: logContext)
        
        return refID
    }
    
    /// Creates a temporary reference entity for the location specified and sets it as the current
    /// destination. When this destination is later cleared, the temporary reference entity will be removed.
    /// This version of the `setDestination` method is intended for custom behaviors that use audio beacons.
    ///
    /// - Parameters:
    ///   - location: Generic location to set as a destination
    ///   - behavior: Name of the custom behavior this beacon is being created for
    ///   - enableAudio: Flag indicating if the beacon should be turned on automatically for the destination
    ///   - userLocation: The user's current location
    ///   - logSource: The context of the call that will be passed to the telemetry service
    /// - Returns: The id of the reference entity set as the destination
    /// - Throws: If the temp reference entity cannot be created or if destination cannot be set
    @discardableResult
    func setDestination(location: CLLocation, behavior: String, enableAudio: Bool, userLocation: CLLocation?, logContext: String?) throws -> String {
        // The generic location cannot already exist if this method is called, so go ahead and create one
        let genericLoc: GenericLocation = GenericLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude, name: GDLocalizationUnnecessary(""))
        let refID = try ReferenceEntity.add(location: genericLoc, nickname: behavior, estimatedAddress: nil, temporary: true)
        
        // Set the newly created generic location as the destination
        try setDestination(referenceID: refID, enableAudio: enableAudio, userLocation: userLocation, logContext: logContext)
        
        return refID
    }
    
    /// Creates a temporary reference entity for the underlying POI with the provided entityKey (if one
    /// doesn't already exist, in which case the existing reference entity will be used), and sets it as
    /// the current destination. When this destination is later cleared, the temporary reference entity
    /// will be removed (if a temporary reference entity was created).
    ///
    /// - Parameters:
    ///   - entityKey: Entity key for the POI to set as the destination
    ///   - enableAudio: Flag indicating if the beacon should be turned on automatically for the destination
    ///   - userLocation: The user's current location
    ///   - estimatedAddress: Estimated address of the POI. Ignored if the entityKey corresponds to a marker
    ///   - logContext: The context of the call that will be passed to the telemetry service
    /// - Returns: The id of the reference entity set as the destination
    /// - Throws: If the temp reference entity cannot be created or if destination cannot be set
    @discardableResult
    func setDestination(entityKey: String, enableAudio: Bool, userLocation: CLLocation?, estimatedAddress: String?, logContext: String?) throws -> String {
        // If the reference entity already exists, just set the destination to that
        if let ref = SpatialDataCache.referenceEntityByEntityKey(entityKey) {
            try setDestination(referenceID: ref.id, enableAudio: enableAudio, userLocation: userLocation, logContext: logContext)
            
            return ref.id
        }
        
        let refID = try ReferenceEntity.add(entityKey: entityKey, nickname: nil, estimatedAddress: estimatedAddress, temporary: true)
        try setDestination(referenceID: refID, enableAudio: enableAudio, userLocation: userLocation, logContext: logContext)
        
        return refID
    }
    
    /// Clears the current destination and removes all temporary reference entities
    /// from the database. If the audio beacon is enabled, it will be turned off.
    /// Finally, this method sends a destination changed notification with a nil ID
    /// after the destination has been cleared.
    ///
    /// - Throws: If temporary reference entities can not be deleted
    func clearDestination(logContext: String?) throws {
        // Remove all temporary reference entities
        try ReferenceEntity.removeAllTemporary()
        
        beaconClosestLocation = nil
        temporaryBeaconClosestLocation = nil
        
        isBeaconInBounds = false
        
        // Clear the destination key to clear the destination
        destinationKey = nil
        
        // Turn off the audio
        proximityBeaconPlayerId = nil
        _beaconPlayerId = nil
        
        hapticBeacon?.stop()
        hapticBeacon = nil
        
        // Log the destination change and notify the rest of the app
        GDATelemetry.track("beacon.removed", with: (logContext != nil) ? ["context": logContext!] : nil)

        notifyDestinationChanged(id: nil)
        
        updateNowPlayingDisplay()
    }
    
    // MARK: Manage Audio Methods
    
    /// Toggles the audio beacon on or off for the current destination.
    ///
    /// - Returns: True if the audio beacon was toggled, false otherwise (e.g. no destination is set or user's location is unknown).
    @discardableResult
    func toggleDestinationAudio(_ sendNotfication: Bool, automatic: Bool, forceMelody: Bool) -> Bool {
        let isRouteBeacon = AppContext.shared.eventProcessor.activeBehavior is RouteGuidance
        guard destination != nil else {
            // Return if destination does not exist
            return false
        }
        
        if isAudioEnabled {
            if !automatic {
                GDATelemetry.track("beacon.toggled", with: ["enabled": "false", "route": String(isRouteBeacon)])
            }
            
            if forceMelody {
                finishBeaconPlayerOnRemove = true
            }
            
            return disableDestinationAudio(sendNotfication)
        }
        
        guard let userLocation = AppContext.shared.geolocationManager.location else {
            return false
        }
        
        if !automatic {
            GDATelemetry.track("beacon.toggled", with: ["enabled": "true", "route": String(isRouteBeacon)])
        }
        
        return enableDestinationAudio(userLocation: userLocation, isUnmuting: !forceMelody, notify: sendNotfication)
    }
    
    /// Moves the beacon's audio to a new location without changing the underlying beacon.
    /// This is primarily used when editing a marker's location using the custom VO experience.
    ///
    /// - Parameters:
    ///   - newLocation: New location for the beacon audio
    ///   - userLocation: User's current location
    ///
    @discardableResult
    func updateDestinationLocation(_ newLocation: CLLocation, userLocation: CLLocation) -> Bool {
        temporaryBeaconClosestLocation = newLocation
        return enableDestinationAudio(beaconLocation: newLocation, userLocation: userLocation, isUnmuting: false, notify: false)
    }
    
    /// Enables the audio beacon sound for the current destination, if one is set.
    ///
    /// - Parameters:
    ///   - beaconLocation: This value is used to temporarily move the beacon from its original location without setting a new beacon. This is primarily used when editing a marker's location using the custom VO experience
    ///   - userLocation: User's current location
    ///   - isUnmuting: Used to determine whether to play the start melody
    ///   - sendNotfication: Should there be a notification telling the rest of the app that the audio was enabled
    ///
    /// - Returns: True is the audio beacon was turned on, false otherwise (e.g. no destination is set).
    @discardableResult
    private func enableDestinationAudio(beaconLocation: CLLocation? = nil, userLocation: CLLocation, isUnmuting: Bool = false, notify sendNotfication: Bool = false) -> Bool {
        guard let destination = destination else {
            // Return if destination could not be retrieved
            return false
        }
        
        var args = BeaconArgs(loc: beaconLocation ?? destination.closestLocation(from: userLocation),
                              heading: Heading(from: collectionHeading),
                              startMelody: SettingsContext.shared.playBeaconStartAndEndMelodies && !isUnmuting,
                              endMelody: SettingsContext.shared.playBeaconStartAndEndMelodies)
        
        if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance || AppContext.shared.eventProcessor.activeBehavior is GuidedTour {
            guard let hum = BeaconSound(ProximityBeacon.self, at: args.loc, isLocalized: false) else {
                return false
            }
            
            proximityBeaconPlayerId = audioEngine.play(hum)
            
            // Always play the start and end melodies in the route guidance (except for when the beacon is just being unmuted)
            args.startMelody = !isUnmuting
            args.endMelody = true
        }
        
        switch SettingsContext.shared.selectedBeacon {
        case V2Beacon.description: playBeacon(V2Beacon.self, args: args)
        case FlareBeacon.description: playBeacon(FlareBeacon.self, args: args)
        case ShimmerBeacon.description: playBeacon(ShimmerBeacon.self, args: args)
        case TactileBeacon.description: playBeacon(TactileBeacon.self, args: args)
        case PingBeacon.description: playBeacon(PingBeacon.self, args: args)
        case DropBeacon.description: playBeacon(DropBeacon.self, args: args)
        case SignalBeacon.description: playBeacon(SignalBeacon.self, args: args)
        case SignalSlowBeacon.description: playBeacon(SignalSlowBeacon.self, args: args)
        case SignalVerySlowBeacon.description: playBeacon(SignalVerySlowBeacon.self, args: args)
        case MalletBeacon.description: playBeacon(MalletBeacon.self, args: args)
        case MalletSlowBeacon.description: playBeacon(MalletSlowBeacon.self, args: args)
        case MalletVerySlowBeacon.description: playBeacon(MalletVerySlowBeacon.self, args: args)
        case HapticWandBeacon.description:
            hapticBeacon = HapticWandBeacon(at: args.loc)
            hapticBeacon?.start()
            isCurrentBeaconAsyncFinishable = false
        case HapticPulseBeacon.description:
            hapticBeacon = HapticPulseBeacon(at: args.loc)
            hapticBeacon?.start()
            isCurrentBeaconAsyncFinishable = false
        default:
            // Always default to the V1 beacon
            playBeacon(ClassicBeacon.self, args: args)
        }
        
        guard beaconPlayerId != nil  || hapticBeacon != nil else {
            GDLogAppError("Unable to start beacon audio player")
            return false
        }
        
        if sendNotfication {
            notifyDestinationAudioChanged()
        }
        
        return true
    }
    
    /// Generic helper function for creating a beacon sound and passing it to the audio engine given a DynamicAudioEngineAsset type
    ///
    /// - Parameters:
    ///   - assetType: Asset type to create a beacon sound for
    ///   - args: Beacon settings
    private func playBeacon<T: DynamicAudioEngineAsset>(_ assetType: T.Type, args: BeaconArgs) {
        guard let sound = BeaconSound(assetType, at: args.loc, includeStartMelody: args.startMelody, includeEndMelody: args.endMelody) else {
            GDLogAppError("Beacon sound failed to load!")
            return
        }
        
        isCurrentBeaconAsyncFinishable = sound.outroAsset != nil
        _beaconPlayerId = audioEngine.play(sound, heading: args.heading)
    }
    
    /// Disables the audio beacon for the current destination, if one is set.
    ///
    /// - Returns: True if the audio beacon was turned off, false otherwise (e.g. no destination is set).
    @discardableResult
    private func disableDestinationAudio(_ sendNotfication: Bool = false) -> Bool {
        guard destination != nil else {
            // Return if destination does not exist
            return false
        }
        
        // Turn off audio
        proximityBeaconPlayerId = nil
        _beaconPlayerId = nil
        
        hapticBeacon?.stop()
        hapticBeacon = nil
        
        if sendNotfication {
            notifyDestinationAudioChanged()
        }
        
        return true
    }
    
    private func updateBeaconClosestLocation(for location: CLLocation) {
        guard let poi = destination?.getPOI() else {
            return
        }
        
        beaconClosestLocation = poi.closestLocation(from: location)
    }
    
    private func isBeaconInBounds(with userHeading: Double) -> Bool {
        guard let userLocation = AppContext.shared.geolocationManager.location else {
            return false
        }
        
        guard let beaconLocation = temporaryBeaconClosestLocation ?? beaconClosestLocation else {
            return false
        }
        
        let bearingToClosestLocation = userLocation.bearing(to: beaconLocation)
        
        guard let directionRange = DirectionRange(direction: bearingToClosestLocation, windowRange: 45) else {
            return false
        }
        
        return directionRange.contains(userHeading)
    }
    
    // MARK: Manage Arrival Methods
    
    @objc private func onEnableGeofence(_ notification: NSNotification) {
        isGeofenceEnabled = true
    }
    
    @objc private func onDisableGeofence(_ notification: NSNotification) {
        isGeofenceEnabled = false
    }
    
    func isUserWithinGeofence(_ userLocation: CLLocation) -> Bool {
        guard let poi = destination?.getPOI() else {
            return false
        }
        
        return isLocationWithinGeofence(origin: poi, location: userLocation)
    }
    
    private func isLocationWithinGeofence(origin: POI, location: CLLocation) -> Bool {
        guard isGeofenceEnabled else {
            return false
        }
        
        if origin.contains(location: location.coordinate) {
            return true
        }
        
        let distance = origin.distanceToClosestLocation(from: location)
        
        if isWithinGeofence && distance >= DestinationManager.LeaveImmediateVicinityDistance {
            // Left immediate vicinity
            return false
        } else if !isWithinGeofence && distance <= DestinationManager.EnterImmediateVicinityDistance {
            // Entered immediate vicinity
            return true
        }
        
        // No change
        return isWithinGeofence
    }
    
    private func shouldTriggerGeofence(location: CLLocation) -> Bool {
        guard isGeofenceEnabled else {
            GDLogAppInfo("shouldTriggerGeofence: Geofence disabled!")
            return false
        }
        
        let oldValue = isWithinGeofence
        
        isWithinGeofence = isUserWithinGeofence(location)
        
        if oldValue == isWithinGeofence {
            return false
        }
        
        return true
    }
    
    // MARK: Notifications
    
    @objc private func onLocationUpdated(_ notification: Notification) {
        // TODO: All of this logic (callout and view update logic) should moved into
        //       the BeaconCalloutGenerator
        
        guard !AppContext.shared.eventProcessor.activeBehavior.blockedAutoGenerators.contains(where: { $0 == BeaconCalloutGenerator.self }) else {
            GDLogAutoCalloutInfo("Skipping beacon geofence update. Beacon callouts are managed by the active behavior.")
            return
        }
        
        guard let userInfo = notification.userInfo else {
            GDLogSpatialDataError("Error: No userInfo with location update")
            return
        }
        
        guard let key = destinationKey else {
            return
        }
        
        guard let location = userInfo[SpatialDataContext.Keys.location] as? CLLocation else {
            GDLogSpatialDataError("Error: LocationUpdated notification is missing location")
            return
        }
        
        updateBeaconClosestLocation(for: location)
        
        updateNowPlayingDisplay(for: location)
        
        guard shouldTriggerGeofence(location: location) else {
            return
        }
        
        let wasAudioEnabled = isAudioEnabled
        
        // Disable audio when entering the geofence, but require the user to manually turn audio
        // back on if they leave the geofence
        if isWithinGeofence {
            GDATelemetry.track("beacon.arrived")
            GDATelemetry.helper?.beaconCountArrived += 1
            
            disableDestinationAudio()
        }
        
        GDLogAppInfo("Geofence Triggered: \(isWithinGeofence ? "Entered" : "Exited")")
        
        AppContext.process(BeaconGeofenceTriggeredEvent(beaconId: key,
                                                        didEnter: isWithinGeofence,
                                                        beaconIsEnabled: isAudioEnabled,
                                                        beaconWasEnabled: wasAudioEnabled,
                                                        location: location))
        
        NotificationCenter.default.post(name: Notification.Name.destinationGeofenceDidTrigger,
                                        object: self,
                                        userInfo: [DestinationManager.Keys.destinationKey: key,
                                                   DestinationManager.Keys.geofenceDidEnter: isWithinGeofence,
                                                   DestinationManager.Keys.isAudioEnabled: isAudioEnabled,
                                                   DestinationManager.Keys.wasAudioEnabled: wasAudioEnabled,
                                                   SpatialDataContext.Keys.location: location])
    }
    
    private func updateNowPlayingDisplay(for location: CLLocation? = nil) {
        if appDidInitialize {
            guard !(AppContext.shared.eventProcessor.activeBehavior is RouteGuidance) else {
                // `RouteGuidance` will set the "Now Playing" text
                return
            }
        }
        
        guard let location = location, let destination = destination else {
            AudioSessionManager.removeNowPlayingInfo()
            return
        }
        
        let name = GDLocalizedString("beacon.beacon_on", destination.name)
        let distance = destination.distanceToClosestLocation(from: location)
        let formattedDistance = LanguageFormatter.formattedDistance(from: distance)
        
        AudioSessionManager.setNowPlayingInfo(title: name, subtitle: formattedDistance)
    }
    
    @objc private func onAudioEngineStateChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let stateValue = userInfo[AudioEngine.Keys.audioEngineStateKey] as? Int,
              let state = AudioEngine.State(rawValue: stateValue) else {
                return
        }
        
        if state == .stopped && isAudioEnabled {
            toggleDestinationAudio()
            didInterruptBeacon = true
        } else if state == .started && didInterruptBeacon {
            toggleDestinationAudio()
            didInterruptBeacon = false
        }
    }
    
    @objc private func onAppDidInitialize(_ notification: Notification) {
        appDidInitialize = true
    }
    
    private func notifyDestinationChanged(id: String?) {
        var userInfo: [String: Any]?
        
        if let id = id {
            userInfo = [DestinationManager.Keys.destinationKey: id,
                        DestinationManager.Keys.isAudioEnabled: isAudioEnabled]
        }
        
        DispatchQueue.main.async {
            AppContext.process(BeaconChangedEvent(id: id, audioEnabled: self.isAudioEnabled))
            
            NotificationCenter.default.post(name: Notification.Name.destinationChanged, object: self, userInfo: userInfo)
        }
    }
    
    private func notifyDestinationAudioChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.destinationAudioChanged, object: self, userInfo: [DestinationManager.Keys.isAudioEnabled: self.isAudioEnabled])
        }
    }
    
}
