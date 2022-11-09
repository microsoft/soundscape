//
//  GeolocationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let headingTypeDidUpdate = Notification.Name("HeadingTypeDidUpdate")
}

@objc
class GeolocationManager: NSObject, GeolocationManagerProtocol {
    
    struct Key {
        static let type = "Type"
        static let value = "Value"
        static let accuracy = "Accuracy"
    }
    
    // MARK: Properties
    
    /// Provides the user's GPS location
    private var locationProvider: LocationProvider
    
    /// Provides the orientation of the phone
    private var deviceHeadingProvider: DeviceHeadingProvider
    
    /// Provides the trajectory between location updates
    private var courseProvider: CourseProvider
    
    /// Provides the orientation of the user's head
    private var userHeadingProvider: UserHeadingProvider?
    
    private(set) var isActive = false
    private var snoozeIsEnabled = false
    
    private var clManager: CoreLocationManager
    private var clCourseProvider: FilteredCourseProvider
    
    weak var updateDelegate: GeolocationManagerUpdateDelegate?
    weak var snoozeDelegate: GeolocationManagerSnoozeDelegate?
    
    private(set) var gpxSimulator: GPXSimulator?
    private(set) var gpxTracker: GPXTracker?
    
    var coreLocationServicesEnabled: Bool {
        return CoreLocationManager.locationAvailable
    }
    
    var coreLocationAuthorizationStatus: CoreLocationAuthorizationStatus {
        return clManager.clAuthorizationStatus
    }
    
    func requestCoreLocationAuthorization() {
        clManager.requestLocationAuthorization()
    }
    
    private(set) var location: CLLocation? {
        didSet {
            guard oldValue != location else {
                return
            }
            
            guard let location = location else {
                return
            }
            
            // Propogate location update
            updateDelegate?.didUpdateLocation(location)
        }
    }
    
    private var course: HeadingValue? {
        didSet {
            onHeadingDidUpdate(course, type: .course)
        }
    }
    
    private var deviceHeading: HeadingValue? {
        didSet {
            onHeadingDidUpdate(deviceHeading, type: .device)
        }
    }
    
    private var userHeading: HeadingValue? {
        didSet {
            onHeadingDidUpdate(userHeading, type: .user)
        }
    }
    
    var collectionHeading: Heading {
        return Heading.defaultCollection(course: course, deviceHeading: deviceHeading, userHeading: userHeading, geolocationManager: self)
    }
    
    var presentationHeading: Heading {
        return Heading.defaultPresentation(course: course, deviceHeading: deviceHeading, userHeading: userHeading, geolocationManager: self)
    }
    
    var isSimulatingGPX: Bool {
        guard let gpxSimulator = gpxSimulator else {
            return false
        }
        
        return gpxSimulator.isSimulating
    }
    
    var isTracking: Bool {
        guard let gpxTracker = gpxTracker else {
            return false
        }
        
        return gpxTracker.isTracking
    }
    
    // MARK: Initialization
    
    init(isInMotion: Bool) {
        clManager = CoreLocationManager()
        clCourseProvider = FilteredCourseProvider(rawCourseProvider: clManager, isInMotion: isInMotion)
        
        // Initialize `CoreLocation` providers
        locationProvider = clManager
        courseProvider = clCourseProvider
        deviceHeadingProvider = clManager
        
        super.init()
        
        // Initialize provider delegates
        locationProvider.locationDelegate = self
        courseProvider.courseDelegate = self
        deviceHeadingProvider.headingDelegate = self
    }
    
    // MARK: `GeolocationManager` Life Cycle

    func start() {
        isActive = true
        
        if snoozeIsEnabled {
            locationProvider.stopMonitoringSignificantLocationChanges()
            snoozeIsEnabled = false
        }
        
        // Starts all registered providers
        locationProvider.startLocationUpdates()
        deviceHeadingProvider.startDeviceHeadingUpdates()
        userHeadingProvider?.startUserHeadingUpdates()
        courseProvider.startCourseProviderUpdates()
    }
    
    func stop() {
        isActive = false
        
        // Clear snooze state
        snoozeIsEnabled = false
        
        // Stops all registered providers
        locationProvider.stopLocationUpdates()
        deviceHeadingProvider.stopDeviceHeadingUpdates()
        userHeadingProvider?.stopUserHeadingUpdates()
        courseProvider.stopCourseProviderUpdates()
        
        // Remove all provider data
        location = nil
        course = nil
        deviceHeading = nil
        userHeading = nil
    }
    
    func snooze() {
        // Start updates based on significant location changes
        guard locationProvider.startMonitoringSignificantLocationChanges() else {
            // Failed to snooze
            snoozeDelegate?.snoozeDidFail()
            return
        }
        
        snoozeIsEnabled = true
    }
    
    // MARK: Providers
    
    func add(_ provider: LocationProvider) {
        // Stop previous provider
        self.locationProvider.stopLocationUpdates()
        
        // Remove provider delegate
        self.locationProvider.locationDelegate = nil
        
        // Remove provider data
        location = nil
        
        // Set new provider and delegate
        self.locationProvider = provider
        self.locationProvider.locationDelegate = self
        
        if isActive {
            locationProvider.startLocationUpdates()
        }
    }
    
    /// Removes a custom location provider and adds the default CoreLocation provider again. If
    /// the current provider is the default CoreLocation provider, this method will do nothing.
    ///
    /// - Parameter provider: Location provider to remove
    func remove(_ provider: LocationProvider) {
        // We can't remove a provider we don't have
        guard provider.id == locationProvider.id else {
            return
        }
        
        // Adding the CoreLocation manager will remove the current custom provider
        add(clManager)
    }
    
    func add(_ provider: CourseProvider) {
        // Stop previous provider
        self.courseProvider.stopCourseProviderUpdates()
        
        // Remove provider delegate
        self.courseProvider.courseDelegate = nil
        
        // Remove provider data
        course = nil
        
        // Set new provider and delegate
        self.courseProvider = provider
        self.courseProvider.courseDelegate = self
        
        if isActive {
            courseProvider.startCourseProviderUpdates()
        }
    }
    
    /// Removes a custom course provider and adds the default CoreLocation course provider again. If
    /// the current provider is the default course provider, this method will do nothing.
    ///
    /// - Parameter provider: Course provider to remove
    func remove(_ provider: CourseProvider) {
        // We can't remove a provider we don't have
        guard provider.id == courseProvider.id else {
            return
        }
        
        // Adding the CoreLocation manager will remove the current custom provider
        add(clCourseProvider)
    }
    
    func add(_ provider: UserHeadingProvider) {
        // If there is an existing provider,
        // remove it
        if let userHeadingProvider = userHeadingProvider {
            remove(userHeadingProvider)
        }
        
        userHeadingProvider = provider
        userHeadingProvider?.headingDelegate = self
        
        if isActive {
            userHeadingProvider?.startUserHeadingUpdates()
        }
    }
    
    func remove(_ provider: UserHeadingProvider) {
        guard provider.id == userHeadingProvider?.id else {
            return
        }
        
        // Remove provider
        userHeadingProvider?.stopUserHeadingUpdates()
        userHeadingProvider?.headingDelegate = nil
        userHeadingProvider = nil
        
        // Remove provider data
        userHeading = nil
    }
    
    // MARK: GPX Simulator
    
    func start(gpxSimulator: GPXSimulator) {
        guard snoozeIsEnabled == false else {
            return
        }
        
        if self.gpxSimulator != nil {
            stopSimulatingGPX()
        }
        
        // Reset callouts and intersections
        AppContext.process(GPXSimulationStartedEvent())
        
        if gpxSimulator.isBackgroundExecutionEnabled {
            // If the simulator should continue to run in the background,
            // Core Location Services should be enabled
            clManager.forceCoreLocationUpdates = true
        }
        
        self.gpxSimulator = gpxSimulator
        
        // Update the location provider
        add(gpxSimulator)
        
        let isInMotion = AppContext.shared.motionActivityContext.isInMotion
        let simulatorCourseProvider = FilteredCourseProvider(rawCourseProvider: gpxSimulator, isInMotion: isInMotion)
        // Update the course provider
        add(simulatorCourseProvider)
    }
    
    func stopSimulatingGPX() {
        guard snoozeIsEnabled == false, let gpxSimulator = gpxSimulator else {
            return
        }
        
        if gpxSimulator.isBackgroundExecutionEnabled {
            // Core Location Services do not need to be enabled
            clManager.forceCoreLocationUpdates = false
        }
        
        // Update the location provider
        add(clManager)
        
        // Update the course provider
        add(clCourseProvider)
        
        self.gpxSimulator = nil
    }
    
    func start(gpxTracker: GPXTracker) {
        guard snoozeIsEnabled == false else {
            return
        }
        
        self.gpxTracker = gpxTracker
        
        if isActive {
            gpxTracker.startTracking()
        }
    }
    
    func stopTrackingGPX() {
        guard snoozeIsEnabled == false else {
            return
        }
        
        self.gpxTracker?.stopTracking()
        self.gpxTracker = nil
    }
    
    // MARK: Heading
    
    func heading(orderedBy types: [HeadingType]) -> Heading {
        return Heading(orderedBy: types, course: course, deviceHeading: deviceHeading, userHeading: userHeading, geolocationManager: self)
    }
    
    private func onHeadingDidUpdate(_ headingValue: HeadingValue?, type headingType: HeadingType) {
        var userInfo: [String: Any] = [Key.type: headingType]
        
        if let headingValue = headingValue {
            userInfo[Key.value] = headingValue.value
            
            if let accuracy = headingValue.accuracy {
                userInfo[Key.accuracy] = accuracy
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name.headingTypeDidUpdate, object: self, userInfo: userInfo)
        
        // [CMH] verbose logging for is enbabled via debug settings
        GDLogHeadphoneMotionVerbose("Heading Update: course - \(course?.value ?? -1.0), user - \(userHeading?.value ?? -1.0), device - \(deviceHeading?.value ?? -1.0)")
    }
    
    // MARK: SwiftUI Location Mocking
    
    func mockLocation(_ mock: CLLocation) {
        self.location = mock
    }
}

extension GeolocationManager: LocationProviderDelegate {
    
    func locationProvider(_ provider: LocationProvider, didUpdateLocation location: CLLocation?) {
        // Location update is in response to
        // triggering a significant location
        // change
        if snoozeIsEnabled {
            snoozeIsEnabled = false
            snoozeDelegate?.snoozeDidTrigger()
            return
        }
        
        // Location update is a result of normal
        // operation
        guard let location = location else {
            // Do not propagate location update when value
            // is `nil`
            return
        }
        
        if let gpxTracker = self.gpxTracker, gpxTracker.isTracking {
            let activity = AppContext.shared.motionActivityContext.currentActivity.rawValue
            let gpxLocation = GPXLocation(location: location, deviceHeading: deviceHeading?.value, activity: activity)
            // Add to GPX file
            gpxTracker.track(location: gpxLocation)
        }
        
        // Save location update
        self.location = location
    }
    
}

extension GeolocationManager: DeviceHeadingProviderDelegate {
 
    func deviceHeadingProvider(_ provider: DeviceHeadingProvider, didUpdateDeviceHeading heading: HeadingValue?) {
        deviceHeading = heading
    }
    
}

extension GeolocationManager: UserHeadingProviderDelegate {
    
    func userHeadingProvider(_ provider: UserHeadingProvider, didUpdateUserHeading heading: HeadingValue?) {
        userHeading = heading
    }
    
}

extension GeolocationManager: CourseProviderDelegate {
    
    func courseProvider(_ provider: CourseProvider, didUpdateCourse course: HeadingValue?) {
        self.course = course
    }
    
}

// MARK: `AsyncAuthorizationProvider`

extension GeolocationManager: AsyncAuthorizationProvider {
    
    var authorizationDelegate: AsyncAuthorizationProviderDelegate? {
        get {
            return clManager.authorizationDelegate
        }
        set {
            clManager.authorizationDelegate = newValue
        }
    }
    
    var authorizationStatus: AuthorizationStatus {
        return clManager.authorizationStatus
    }
    
    func requestAuthorization() {
        requestCoreLocationAuthorization()
    }
    
}
