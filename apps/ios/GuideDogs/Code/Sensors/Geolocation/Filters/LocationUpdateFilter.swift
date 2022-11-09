//
//  LocationUpdateFilter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// This class acts as a filter for throttling the frequency of computation which is
/// initiated by geolocation updates. With code that is dependent on location updates
/// it is often the case that it is unnecessary to run the code as often as iOS provides
/// location updates. For instance, it is unnecessary to make requests to the service
/// layer for new tiles every time a location update is delivered by iOS. For situations
/// like that, this class can be used to ensure a certain amount of time has past or the
/// user has moved a minimum distance since the code was last run. To use this class,
/// instantiate an object with the minimum time and distance to use for throttling. Then
/// use shouldUpdate(:CLLocation?) each time a geolocation update is delivered from iOS
/// to check if it is time to run the code in question. If shouldUpdate(:CLLocation?) returns
/// true and you execute the code, then call update(:CLLocation?) to inform the object that
/// an update has in fact occurred.
class LocationUpdateFilter {
    
    // MARK: Static Properties
    
    /// Value for Double properties which do not have a previously set value
    private static let NoPreviousValue: Double = -1.0
    
    // MARK: Properties
    
    /// The previous time the filter was updated
    private(set) var previousTime: Date?
    
    /// The previous location the filter was updated at
    private(set) var previousLocation: CLLocation?
    
    /// The amount of time that elapsed between the last two updates
    private(set) var previousElapsed: TimeInterval
    
    /// The amount of distance that elapsed between the last two updates
    private(set) var previousDistance: CLLocationDistance
    
    /// Indicates if the filter is in the reset state (`false`) or if `update(...)` has been called (`true`)
    var hasPrevious: Bool {
        return previousDistance != LocationUpdateFilter.NoPreviousValue && previousElapsed != LocationUpdateFilter.NoPreviousValue
    }
    
    /// The minimum time interval between updates
    let updateTimeInterval: TimeInterval

    /// The minimum distance between updates
    let updateDistanceInterval: CLLocationDistance
    
    // MARK: Initializers
    
    /// Initializes a LocationUpdateFilter with the minimum distance and time between updates.
    ///
    /// - Parameters:
    ///   - minTime: Minimum amount of time that must elapse between updates
    ///   - minDistance: Minimum distance the user must travel between updates
    init(minTime: TimeInterval, minDistance: CLLocationDistance) {
        previousElapsed = LocationUpdateFilter.NoPreviousValue
        previousDistance = LocationUpdateFilter.NoPreviousValue
        
        updateTimeInterval = minTime
        updateDistanceInterval = minDistance
    }
    
    // MARK: Methods
    
    /// Notifies the filter that an update has occurred.
    ///
    /// - Parameter location: The user's location when the update occurred
    func update(location: CLLocation) {
        if let previousTime = previousTime {
            self.previousElapsed = Date().timeIntervalSince(previousTime)
        }
        
        if let previousLocation = previousLocation {
            self.previousDistance = previousLocation.distance(from: location)
        }
        
        // Set the update time to now, and the location to the provided location
        self.previousTime = Date()
        self.previousLocation = location
    }
    
    /// Resets the filter (ensuring that the next call to shouldUpdate(:CLLocation?) will return true
    func reset() {
        previousElapsed = LocationUpdateFilter.NoPreviousValue
        previousDistance = LocationUpdateFilter.NoPreviousValue
        
        previousLocation = nil
        previousTime = nil
    }
    
    /// Checks if the minimum time AND distance have been passed (both conditions must be met).
    /// In the case that the filter has just been initialized (or reset), this method will return true.
    /// If the provided `location` is `nil`, this method will return false (the distance condition
    /// can not be verified without the user's current location).
    ///
    /// - Parameter location: The user's current location
    /// - Returns: True if it is OK to update, or false otherwise
    func shouldUpdate(location: CLLocation) -> Bool {
        return shouldUpdate(location: location, updateTimeInterval: updateTimeInterval, updateDistanceInterval: updateDistanceInterval)
    }
    
    func shouldUpdate(location: CLLocation, updateTimeInterval: TimeInterval, updateDistanceInterval: CLLocationDistance) -> Bool {
        // If we don't have a previous location or time, then by default we should update
        guard let previousLocation = previousLocation else {
            return true
        }
        
        guard let previousTime = previousTime else {
            return true
        }
        
        // If the user has moved at least (updateDistanceInterval) meters, and at least (updateTimeInterval) seconds
        // have passed, then we should update
        let dist = location.distance(from: previousLocation)
        let time = previousTime + updateTimeInterval
                
        if dist > updateDistanceInterval && time < Date() {
            return true
        }
        
        // Neither the time interval nor the distance interval have been passed - no update
        return false
    }
    
}
