//
//  GeneratorUpdateFilter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// This class acts as a filter for throttling the frequency of computation which is
/// initiated by various state change updates in Soundscape (e.g. geolocation updates).
/// With code that is dependent on location updates it is often unnecessary to run the code as
/// often state changes occur. For instance, it is unnecessary to make requests to the service
/// layer for new tiles every time a location update is delivered by iOS. For situations
/// like that, this class can be used to ensure a certain amount of time has past AND the
/// user has moved a minimum distance since the code was last run.
///
/// To use this class, instantiate an object with the minimum time and distance to use for
/// throttling. Call `shouldUpdate(location:)` each time a state change triggers your update code
/// to check if the update should be skipped or not. If `shouldUpdate(location:)` returns
/// `true` and you execute the code, then call `isUpdating(location:)`. When the code finishes
/// updating, call `didUpdate(success:)` to inform the filter object that the update has finished.
/// While an update is running, the filter will always return `false` from `shouldUpdate(location:)`
/// to prevent simultaneous updates.
class GeneratorUpdateFilter {
    
    // MARK: Configuration Properties
    
    /// A reference to the MotionActivityContext for cases in which the filter
    /// should increase the updateDistanceInterval by a multiple when the user
    /// is in a vehicle.
    private weak var activityContext: MotionActivityContext?
    
    /// The minimum time interval between updates
    let updateTimeInterval: TimeInterval
    
    /// The minimum distance between updates
    let updateDistanceInterval: CLLocationDistance
    
    /// Multiplier for the updateDistanceInterval when the user is in a vehicle. This is only used
    /// when `activityContext` is not nil.
    let vehicleUpdateDistanceMultiplier: Double
    
    // MARK: State Properties
    
    /// State of the filter (location and time) when the most recent update occured
    private(set) var lastUpdate: FilterUpdateSnapshot?
    
    /// Indicates if the filter is in the reset state (`false`) or if `update(...)` has been called (`true`)
    var hasPrevious: Bool {
        return lastUpdate != nil
    }
    
    /// Indicates if `isUpdating(location:)` has been called, but `didUpdate(success:)` has
    /// not yet been called. If this is `true`, then `shouldUpdate(location:)` will always return `false`.
    private var isUpdating: Bool = false
    
    /// Tracks the location of an update that is currently occurring (i.e. after `isUpdating(location:)`
    /// has been called and before `didUpdate()` has been called).
    private var currentUpdateLocation: CLLocation?
    
    // MARK: Initializers
    
    /// Initializes a GeneratorUpdateFilter with the minimum distance the user must move and the minimum
    /// time that must elapse between updates. Note that the filter will only return `true` from
    /// `shouldUpdate(location:)` when both the minimum distance and minimum time have elapsed.
    ///
    /// - Parameters:
    ///   - time: Minimum amount of time that must elapse between updates
    ///   - distance: Minimum distance the user must travel between updates
    init(time: TimeInterval, distance: CLLocationDistance) {
        updateTimeInterval = time
        updateDistanceInterval = distance
        vehicleUpdateDistanceMultiplier = 1
    }
    
    /// Initializes a GeneratorUpdateFilter with the minimum distance the user must move and the minimum
    /// time that must elapse between updates, and a multiplier that should be applied to the minimum distance
    /// when the user is in a vehicle. This ensures that users won't hear continuous callouts while in
    /// a vehicle such as a bus. Note that the filter will only return `true` from `shouldUpdate(location:)`
    /// when both the minimum distance and minimum time have elapsed.
    ///
    /// - Parameters:
    ///   - time: Minimum amount of time that must elapse between updates
    ///   - distance: Minimum distance the user must travel between updates
    ///   - activity: The motion activity context
    ///   - multiplier: A multiplier to apply to the `minDistance` when the user is in a vehicle
    init(time: TimeInterval, distance: CLLocationDistance, activity: MotionActivityContext, multiplier: Double = 4.0) {
        updateTimeInterval = time
        updateDistanceInterval = distance
        activityContext = activity
        vehicleUpdateDistanceMultiplier = multiplier
    }
    
    // MARK: Methods
    
    /// Checks if the minimum time AND distance have been passed (both conditions must be met).
    /// In the case that the filter has just been initialized (or reset), this method will return true.
    /// If the provided `location` is `nil`, this method will return false (the distance condition
    /// can not be verified without the user's current location).
    ///
    /// - Parameter location: The user's current location
    /// - Returns: True if it is OK to update, or false otherwise
    func shouldUpdate(location: CLLocation) -> Bool {
        return shouldUpdate(location: location, minTime: updateTimeInterval, minDistance: updateDistanceInterval)
    }
    
    func shouldUpdate(location: CLLocation, minTime: TimeInterval, minDistance: CLLocationDistance) -> Bool {
        guard !isUpdating else {
            return false
        }
        
        // If we don't have a previous update, then by default we should update
        guard let lastUpdate = lastUpdate else {
            return true
        }
        
        // Check if we need a multiplier other than 1
        var multiplier = 1.0
        if let activityContext = activityContext, activityContext.isInVehicle {
            multiplier = vehicleUpdateDistanceMultiplier
        }
        
        // If the user has moved at least (updateDistanceInterval) meters, and at least (updateTimeInterval) seconds
        // have passed, then we should update
        let distCheck = location.distance(from: lastUpdate.location) > minDistance * multiplier
        let timeCheck = lastUpdate.time + minTime < Date()
        
        return distCheck && timeCheck
    }
    
    /// This method notifies the filter when an update has begun but not yet completed. After
    /// calling this method, the filter will return `false` from `shouldUpdate(location:)` until
    /// `didUpdate(success:)` is called. This ensures that the object using this filter doesn't run
    /// additional updates while the previous update is still being processed.
    ///
    /// - Parameter location: The location at which the location update began
    func isUpdating(location: CLLocation) {
        currentUpdateLocation = location
        isUpdating = true
    }
    
    /// This method updates the filter in the event that was synchronously completed.
    ///
    /// - Parameters:
    ///   - location: The location at which the location update occurred
    ///   - success: True if the update successfully completed or false if the update failed or was cancelled
    func didUpdate(location: CLLocation, success: Bool) {
        isUpdating(location: location)
        didUpdate(success: success)
    }
    
    /// Notifies the filter that an update has occurred. This method should be called after
    /// `isUpdating(location:)` unless the update was immediately completed after calling
    /// `shouldUpdate(location:)`.
    ///
    /// - Parameter success: True if the update successfully completed or false if the update failed or was cancelled
    func didUpdate(success: Bool) {
        defer {
            isUpdating = false
            currentUpdateLocation = nil
        }
        
        // The update must have already been running (`isUpdating(location:)` needs to be called before starting an update).
        guard isUpdating, let updateLocation = currentUpdateLocation else {
            return
        }
        
        // The update should be successful if we are going to update the filter's state. Otherwise, don't track
        // the update, allowing another one occur
        guard success else {
            return
        }
        
        guard let previous = lastUpdate else {
            lastUpdate = FilterUpdateSnapshot(updateLocation)
            return
        }
        
        lastUpdate = FilterUpdateSnapshot(updateLocation, elapsed: Date().timeIntervalSince(previous.time), distance: previous.location.distance(from: updateLocation))
    }
    
    /// Resets the filter (ensuring that the next call to `shouldUpdate(location:)` will return true
    func reset() {
        lastUpdate = nil
        isUpdating = false
        currentUpdateLocation = nil
    }
    
}
