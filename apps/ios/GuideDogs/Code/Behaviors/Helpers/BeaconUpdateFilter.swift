//
//  BeaconUpdateFilter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// This class acts as a filter for throttling the frequency of beacon distance callouts
/// on the basis of geolocation updates. This filter allows for beacon distance callouts
/// to occur more frequently as the distance between the user and the beacon's location
/// decreases (i.e. callout frequency increases as relevance/importance increases). Unlike
/// other similar update filters, this filter does not throttle updates on the basis of
/// time.
///
/// To use this class, instantiate an object with the minimum time and distance to
/// use for throttling. Call `shouldUpdate(location:)` each time a state change triggers
/// your update code to check if the update should be skipped or not. If `shouldUpdate(location:)`
/// returns `true` and you execute the code, then call `isUpdating(location:)`. When the code finishes
/// updating, call `didUpdate(success:)` to inform the filter object that the update has finished.
/// While an update is running, the filter will always return `false` from `shouldUpdate(location:)`
/// to prevent simultaneous updates.
class BeaconUpdateFilter {
    
    private enum DistanceRange {
        case beacon, update
    }
    
    // MARK: Configuration Properties
    
    /// The motion activity that tracks the current user activity
    let motionActivity: MotionActivityProtocol
    
    /// We use this property to estimate how much faster a user is moving when driving versus walking
    /// so that we can scale the update ranges by this factor if the user is in a car rather than walking
    var estimatedWalkingSpeed: Double = 2
    
    /// Range defining the minimum distance the user must travel from the last update
    /// before another update will trigger
    let baseUpdateDistanceRange: Range<CLLocationDistance>
    
    /// Range defining the distances from the beacon over which callout frequency should
    /// be interpolated using the callout distance range
    let baseBeaconDistanceRange: Range<CLLocationDistance>
    
    private var shouldIgnoreFirstUpdate: Bool = false
    
    private var slope: Double
    
    private var beaconLocation: CLLocation?
    
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
    
    /// Initializes a BeaconUpdateFilter with the minimum distance the user must move and the minimum
    /// time that must elapse between updates. Note that the filter will only return `true` from
    /// `shouldUpdate(location:)` when both the minimum distance and minimum time have elapsed.
    ///
    /// - Parameters:
    ///   - updateDistance: Range defining the minimum distance the user must travel from the
    ///                     last update before another update will trigger
    ///   - beaconDistance: Range defining the distances from the beacon over which callout
    ///                     frequency should be interpolated using the callout distance range
    init(updateDistance: Range<CLLocationDistance>, beaconDistance: Range<CLLocationDistance>, motionActivity: MotionActivityProtocol) {
        self.motionActivity = motionActivity
        baseUpdateDistanceRange = updateDistance
        baseBeaconDistanceRange = beaconDistance
        slope = (updateDistance.upperBound - updateDistance.lowerBound) / (beaconDistance.upperBound - beaconDistance.lowerBound)
    }
    
    // MARK: Methods
    
    func start(beaconLocation: CLLocation, shouldIgnoreFirstUpdate: Bool = false) {
        // Ensure we are starting in a clean state
        reset()
        
        // Track the beacon's location
        self.beaconLocation = beaconLocation
        self.shouldIgnoreFirstUpdate = shouldIgnoreFirstUpdate
        
        GDLogVerbose(.routeGuidance, "Beacon update filter started!")
    }
    
    private func updateRange(for range: DistanceRange, location: CLLocation) -> Range<CLLocationDistance> {
        let baseRange = range == .beacon ? baseBeaconDistanceRange : baseUpdateDistanceRange
        
        guard motionActivity.isInVehicle else {
            return baseRange
        }
        
        guard location.speed > estimatedWalkingSpeed else {
            return baseRange
        }
        
        // If the user is driving, we should scale up the range based on how fast they are moving (times 2 to ensure we aren't constantly making callouts in the car)
        let rangeMin = baseRange.lowerBound * location.speed * 2.0
        let rangeMax = baseRange.upperBound * location.speed * 2.0
        return rangeMin ..< rangeMax
    }
    
    func shouldUpdate(location: CLLocation) -> Bool {
        guard let beaconLocation = beaconLocation, !isUpdating else {
            return false
        }
        
        // If we don't have a previous update, then by default we should update
        guard let lastUpdate = lastUpdate else {
            // If we are supposed to ignore the first update, then log is as a successful update and move on
            if shouldIgnoreFirstUpdate {
                didUpdate(location: location, success: true)
                return false
            }
            
            return true
        }
        
        let beaconDistanceRange = updateRange(for: .beacon, location: location)
        let updateDistanceRange = updateRange(for: .update, location: location)
        let distanceToBeacon = location.distance(from: beaconLocation)
        let distanceFromLastUpdate = location.distance(from: lastUpdate.location)
        
        if distanceToBeacon >= beaconDistanceRange.upperBound {
            GDLogVerbose(.routeGuidance, "Checking should update... Distance to beacon greater than far range (\(beaconDistanceRange.upperBound.roundToDecimalPlaces(1))m), Distance from last update \(distanceFromLastUpdate.roundToDecimalPlaces(1))m")
            return distanceFromLastUpdate >= updateDistanceRange.upperBound
        } else if distanceToBeacon < beaconDistanceRange.lowerBound {
            GDLogVerbose(.routeGuidance, "Checking should update... Arrived!")
            return true
        } else {
            let currentBound = slope * (distanceToBeacon - beaconDistanceRange.lowerBound) + updateDistanceRange.lowerBound
            GDLogVerbose(.routeGuidance, "Checking should update... Inside beacon distance range (current bound: \(currentBound.roundToDecimalPlaces(1))m), Distance from beacon \(distanceToBeacon.roundToDecimalPlaces(1))m, Distance from last update \(distanceFromLastUpdate.roundToDecimalPlaces(1))m")
            return distanceFromLastUpdate >= currentBound
        }
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
        
        guard let beacon = beaconLocation else {
            return
        }
        
        // If an update has been completed and the distance to the beacon is below the beacon distance
        // range, then the user has arrived, so we should clear the beacon location in order to stop
        // allowing updates
        let distance = updateLocation.distance(from: beacon)
        let beaconDistanceRange = updateRange(for: .beacon, location: updateLocation)
        if distance < beaconDistanceRange.lowerBound {
            beaconLocation = nil
        }
        
        GDLogVerbose(.routeGuidance, "Beacon distance callout occurred: Beacon \(distance.roundToDecimalPlaces(1))m away")
        
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
