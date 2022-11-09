//
//  CoreLocationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// Constants indicating the app's authorization to use core location services and the accuracy.
enum CoreLocationAuthorizationStatus {
    /// `CLAuthorizationStatus` is `whenInUse` or `always` and accuracy is `full`
    case fullAccuracyLocationAuthorized
    
    /// `CLAuthorizationStatus` is `whenInUse` or `always` and accuracy is `reduced`
    case reducedAccuracyLocationAuthorized
    
    /// `CLAuthorizationStatus` is `notDetermined`
    case notDetermined
    
    /// `CLAuthorizationStatus` is `denied` or `restricted`
    case denied
}

class CoreLocationManager: NSObject {
    
    // MARK: Enums
    
    enum LocationUpdateActivity: Equatable {
        case continuous
        case startingSignificantChange
        case significantChange(origin: SignificantChangeMonitoringOrigin)
        case none
        
        static func == (lhs: LocationUpdateActivity, rhs: LocationUpdateActivity) -> Bool {
            switch  (lhs, rhs) {
            case (.continuous, .continuous): return true
            case(.startingSignificantChange, .startingSignificantChange): return true
            case (let .significantChange(originA), let .significantChange(originB)): return originA == originB
            case (.none, .none): return true
            default: return false
            }
        }
    }
    
    // MARK: Properties
    
    let id: UUID = .init()
    
    private var locationUpdateActivity: LocationUpdateActivity = .none
    private var isCourseActive = false
    private var isDeviceHeadingActive = false
    private let locationManager = CLLocationManager()
    private let filter = KalmanFilter(sigma: 3.0)
    weak var authorizationDelegate: AsyncAuthorizationProviderDelegate?
    
    // Provider Delegates
    weak var locationDelegate: LocationProviderDelegate?
    weak var headingDelegate: DeviceHeadingProviderDelegate?
    weak var courseDelegate: RawCourseProviderDelegate?
    
    private var isLocationActive: Bool {
        return locationUpdateActivity != .none
    }
    
    private var isSignificantLocationChangeActive: Bool {
        if locationUpdateActivity == .startingSignificantChange {
            return true
        }
        
        if case .significantChange = locationUpdateActivity {
            return true
        }
        
        return false
    }
    
    // Authorization
    
    /// Wraps `clAuthorizationStatus` in a value expected by `AuthorizationProvider` APIs and associated
    /// UI
    var authorizationStatus: AuthorizationStatus {
        switch clAuthorizationStatus {
        case .fullAccuracyLocationAuthorized: return .authorized
        case .notDetermined: return .notDetermined
        case .denied, .reducedAccuracyLocationAuthorized: return .denied
        }
    }
    
    /// Used to track the initial automatic call to `locationManagerDidChangeAuthorization()`.
    ///
    /// Apple: "Core Location always calls `locationManagerDidChangeAuthorization()` when your app creates an instance of `CLLocationManager`."
    private var didReceiveInitialAuthorizationCall: Bool = false
    
    /// Authorization status which includes details specific to `CoreLocation` (e.g., location accuracy)
    var clAuthorizationStatus: CoreLocationAuthorizationStatus {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return isFullAccuracyAuthorized ? .fullAccuracyLocationAuthorized : .reducedAccuracyLocationAuthorized
        case .notDetermined:
            return .notDetermined
        default:
            return .denied
        }
    }
    
    var isFullAccuracyAuthorized: Bool {
        switch locationManager.accuracyAuthorization {
        case .fullAccuracy:
            return true
        default:
            return false
        }
    }
    
    static var locationAvailable: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    static var headingAvailable: Bool {
        return CLLocationManager.headingAvailable()
    }
    
    // Expected state is subject to context of use
    // `State.default` - requires that the UI device is
    // held flat or that the app is in the foreground
    private var isUIDeviceInExpectedState: Bool = true {
        didSet {
            guard oldValue != isUIDeviceInExpectedState else {
                return
            }
            
            if isUIDeviceInExpectedState {
                guard let heading = locationManager.heading, let value = value(for: heading) else {
                    // Current heading is invalid
                    return
                }
                
                // Device is in the expected state, so the current
                // heading is valid
                // Propogate current heading
                if isDeviceHeadingActive {
                    headingDelegate?.deviceHeadingProvider(self, didUpdateDeviceHeading: value)
                }
            } else {
                // Device is not in expected state, so the
                // current heading is invalid
                // Propogate `nil`
                if isDeviceHeadingActive {
                    headingDelegate?.deviceHeadingProvider(self, didUpdateDeviceHeading: nil)
                }
            }
        }
    }
    
    var forceCoreLocationUpdates = false {
        didSet {
            guard oldValue != forceCoreLocationUpdates else {
                return
            }
            
            guard isLocationActive == false else {
                // `isLocationActive` represents the state that location
                // updates should be in if `forceCoreLocationUpdates` is false
                //
                // There is nothing to do if Core Location
                // Services are already running
                return
            }
            
            if forceCoreLocationUpdates {
                // Core Location Services should be enabled
                // Start location updates
                startCoreLocationUpdates(significantChange: false)
            } else if forceCoreLocationUpdates == false {
                // Core Location Services do not need to be enabled
                // Stop location updates
                stopCoreLocationUpdates()
            }
        }
    }
    
    // MARK: Initialization
    
    override init() {
        super.init()
        
        // Initialize `CLLocationManager`
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onUIDeviceStateDidChange(notification:)),
                                               name: Notification.Name.uiDeviceStateDidChange,
                                               object: nil)
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: Manage Updates
    
    @discardableResult
    private func startCoreLocationUpdates(significantChange: Bool) -> Bool {
        guard CoreLocationManager.locationAvailable else {
            // Location updates are not available
            return false
        }
        
        guard clAuthorizationStatus == .fullAccuracyLocationAuthorized else {
            // Core Location services are not authorized
            return false
        }
        
        // Configure update properties
        locationManager.distanceFilter = significantChange ? CLLocationDistance(10.0) : CLLocationDistance(1.0)
        locationManager.desiredAccuracy = significantChange ? kCLLocationAccuracyNearestTenMeters : kCLLocationAccuracyBestForNavigation
        // Ensure we can still get background updates
        locationManager.showsBackgroundLocationIndicator = true
        
        if locationUpdateActivity == .none {
            // Start location updates
            locationManager.startUpdatingLocation()
        }
        
        return true
    }
    
    private func stopCoreLocationUpdates() {
        guard forceCoreLocationUpdates == false else {
            // `forceCoreLocationUpdates` will be set when there are tasks
            // that need to be executed in the background (e.g. simulating GPX)
            //
            // Do not stop Core Location Services
            return
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    func startLocationUpdates() {
        guard locationUpdateActivity != .continuous else {
            // Location updates have already been started
            return
        }
        
        // If we have already started course updates,
        // we do not need to start CL location updates
        guard isCourseActive || startCoreLocationUpdates(significantChange: false) else {
            // Failed to start CL location updates
            return
        }
        
        locationUpdateActivity = .continuous
        
        // Force an initial update with the latest location if one exists...
        if let initial = locationManager.location {
            didUpdateLocation(initial)
        }
    }
    
    func stopLocationUpdates() {
        guard locationUpdateActivity == .continuous else {
            // Location updates have already been stopped
            return
        }
        
        locationUpdateActivity = .none
        
        guard isCourseActive == false else {
            // If we are still collecting course updates,
            // do not stop CL location updates
            return
        }
        
        stopCoreLocationUpdates()
    }
    
    func startCourseProviderUpdates() {
        if isSignificantLocationChangeActive {
            // Course updates should not be started when monitoring for
            // significant change
            return
        }
        
        guard isCourseActive == false else {
            // Course updates have already been started
            return
        }
        
        // If we have already started location updates
        // we do not need to start CL course updates
        guard locationUpdateActivity == .continuous || startCoreLocationUpdates(significantChange: false) else {
            // Failed to start CL location updates
            return
        }
        
        isCourseActive = true
    }
    
    func stopCourseProviderUpdates() {
        guard isCourseActive else {
            // Course updates have already been stopped
            return
        }
        
        isCourseActive = false
        
        guard locationUpdateActivity == .none else {
            // If we are still collecting location updates,
            // do not stop CL location updates
            return
        }
        
        stopCoreLocationUpdates()
    }
    
    func startDeviceHeadingUpdates() {
        guard isDeviceHeadingActive == false else {
            // Device heading updates have already been started
            return
        }
        
        guard CoreLocationManager.headingAvailable else {
            // Device heading updates are not available
            return
        }

        // For heading updates, either full or reduced location accuracy is suffice
        guard clAuthorizationStatus == .fullAccuracyLocationAuthorized || clAuthorizationStatus == .reducedAccuracyLocationAuthorized else {
            // Core Location services are not authorized
            return
        }
        
        // Configure update properties
        locationManager.headingFilter = CLLocationDegrees(1.0)
        // Start updating
        locationManager.startUpdatingHeading()
        
        isDeviceHeadingActive = true
    }
    
    func stopDeviceHeadingUpdates() {
        guard isDeviceHeadingActive else {
            // Device heading updates have already been stopped
            return
        }
        
        isDeviceHeadingActive = false
        
        locationManager.stopUpdatingHeading()
    }
    
    private func didUpdateLocation(_ location: CLLocation) {
        if case .significantChange(let origin) = locationUpdateActivity {
            // Do not propogate location update if there is no
            // significant change
            guard origin.shouldUpdateLocation(location) else {
                return
            }
        }
        
        // `course` is valid if its value is >= 0.0
        let course = location.course < 0 ? nil : location.course
        // `speed` is valid if its value is >= 0.0
        let speed = location.speed < 0 ? nil : location.speed
        
        var headingValue: HeadingValue?
        
        if let course = course {
            headingValue = HeadingValue(course, nil)
        }
        
        // If location updates are enabled,
        // propogate location update
        if isLocationActive {
            locationDelegate?.locationProvider(self, didUpdateLocation: location)
        }
        
        // If course updates are enabled,
        // propogate course update
        if isCourseActive {
            courseDelegate?.courseProvider(self, didUpdateCourse: headingValue, speed: speed)
        }
    }
    
    // MARK: Heading
    
    private func value(for newHeading: CLHeading) -> HeadingValue? {
        guard isUIDeviceInExpectedState else {
            // `newHeading` is invalid if device is
            // not in expected state
            return nil
        }
        
        // Use `trueHeading` if it is valid
        // `trueHeading` is valid if its value is >= 0.0
        if newHeading.trueHeading >= 0.0 {
            return HeadingValue(newHeading.trueHeading, newHeading.headingAccuracy)
        }
        
        // Use `magneticHeading` if it is valid
        // `magneticHeading` is valid if `headingAccuracy` is >= 0.0
        if newHeading.headingAccuracy >= 0.0 {
            return HeadingValue(newHeading.magneticHeading, newHeading.headingAccuracy)
        }
        
        // `newHeading` is invalid
        return nil
    }
    
    // MARK: Notifications
    
    @objc
    private func onUIDeviceStateDidChange(notification: Notification) {
        guard let state = notification.userInfo?[UIDeviceManager.Keys.state] as? UIDeviceManager.State else {
            return
        }
        
        if state == .default {
            isUIDeviceInExpectedState = true
        } else {
            isUIDeviceInExpectedState = false
        }
    }
    
}

// MARK: - CLLocationManagerDelegate

extension CoreLocationManager: CLLocationManagerDelegate {
    
    /// iOS < 14
    /// Invoked when either `authorizationStatus` or `accuracyAuthorization` proparty  values change
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard didReceiveInitialAuthorizationCall else {
            didReceiveInitialAuthorizationCall = true
            // Method was invoked when an instance of CLLocationManager was created
            // No-op at this time
            return
        }
        
        if !isFullAccuracyAuthorized {
            // If location updates are enabled, propogate `nil`
            if isLocationActive {
                locationDelegate?.locationProvider(self, didUpdateLocation: nil)
            }
            
            // If course updates are enabled, propogate `nil`
            if isCourseActive {
                courseDelegate?.courseProvider(self, didUpdateCourse: nil, speed: nil)
            }
        }
                        
        // Log authorization status
        
        let status: String
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            status = "not_determined"
        case .restricted:
            status = "restricted"
        case .denied:
            status = "denied"
        case .authorizedAlways:
            status = "authorized_always"
        case .authorizedWhenInUse:
            status = "authorized_when_in_use"
        @unknown default:
            status = "unknown - (WARNING) new enum value added"
        }
        
        let accuracy = isFullAccuracyAuthorized ? "full" : "reduced"
        
        GDLogLocationInfo("Location manager did change authorization to: \(status), accuracy: \(accuracy)")
        
        GDATelemetry.track("location_permission_request", with: ["status": status, "accuracy": accuracy])
        
        authorizationDelegate?.authorizationDidChange(authorizationStatus)
    }
    
    /// iOS > 14
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManagerDidChangeAuthorization(manager)
        
        authorizationDelegate?.authorizationDidChange(authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        guard location.horizontalAccuracy >= 0.0 else {
            // Negative value indicates that the latitude and longitude
            // are invalid
            return
        }
        
        // Process via Kalman filter
        let filteredLocation = filter.process(location: location)
        
        if locationUpdateActivity == .startingSignificantChange {
            // When monitoring for significant change in location, use the
            // first location update as the origin
            startMonitoringSignificantLocationChanges(filteredLocation)
        } else {
            // Process location update
            didUpdateLocation(filteredLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isDeviceHeadingActive else {
            // Device heading updates are not enabled
            return
        }
        
        guard let heading = value(for: newHeading) else { return }
        
        // Propogate heading update if `newHeading` is valid
        // and device is in expected state
        headingDelegate?.deviceHeadingProvider(self, didUpdateDeviceHeading: heading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        GDLogLocationError("CLLocationManager did fail with error: \(error.localizedDescription)")
        
        guard let error = error as? CLError else { return }
        
        switch error.code {
        case .denied, .locationUnknown, .headingFailure:
            // If location updates are enabled, propogate `nil`
            if isLocationActive {
                locationDelegate?.locationProvider(self, didUpdateLocation: nil)
            }
            
            // If course updates are enabled, propogate `nil`
            if isCourseActive {
                courseDelegate?.courseProvider(self, didUpdateCourse: nil, speed: nil)
            }
        default:
            break
        }
    }
    
}

// MARK: - DeviceHeadingProvider

extension CoreLocationManager: DeviceHeadingProvider { }

// MARK: - RawCourseProvider

extension CoreLocationManager: RawCourseProvider { }

// MARK: - LocationProvider

extension CoreLocationManager: LocationProvider {
    
    func startMonitoringSignificantLocationChanges() -> Bool {
        guard startCoreLocationUpdates(significantChange: true) else {
            // Failed to start CL location updates
            return false
        }
        
        locationUpdateActivity = .startingSignificantChange
        
        return true
    }
    
    func stopMonitoringSignificantLocationChanges() {
        guard isSignificantLocationChangeActive else {
            // Significant change updates have already
            // been stopped
            return
        }
        
        locationUpdateActivity = .none
        
        // Stop location updates
        locationManager.stopUpdatingLocation()
    }
    
    private func startMonitoringSignificantLocationChanges(_ location: CLLocation) {
        // `SignificantChangeMonitoringOrigin` will decide
        // when a significant change in location has occured
        let origin = SignificantChangeMonitoringOrigin(location)
        locationUpdateActivity = .significantChange(origin: origin)
    }
    
}
