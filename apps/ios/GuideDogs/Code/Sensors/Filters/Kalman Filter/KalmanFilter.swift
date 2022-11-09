//
//  KalmanFilter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Implementation of a Kalman fitler
/// See: https://stackoverflow.com/questions/1134579/smooth-gps-data
class KalmanFilter {
    
    /// The minimum allowable accuracy measurement. Input accuracy values are clamped to this
    /// minimum in order to prevent a division by zero in the `process(:)` method.
    private let minimumAccuracy: Double = 0.1
    
    /// Parameter describing how quickly the accuracy of the current filtered location
    /// degrades in the absence of any additional location updates.
    private let sigma: Double
    
    /// Current covariance of the filter. This value updates each time a new location update is
    /// passed to the filter.
    private var covariance = 0.0
    
    /// Last estimate  computed by the `process(:)` method
    private var estimate: [Double]?
    
    /// Timestamp of last estimate
    private var timestamp: Date?
    
    init(sigma: Double) {
        self.sigma = sigma
    }
    
    func process(newVector: [Double], newTimestamp: Date, newAccuracy: Double) -> [Double]? {
        // Ensure `accuracy >= minimumAccuracy`
        let accuracy = max(newAccuracy, minimumAccuracy)
        
        // Calculate variance
        let measurementVariance = accuracy * accuracy
        
        // Check if the filter is initialized, and initialize it if it isn't
        guard let estimate = estimate, let timestamp = timestamp else {
            self.estimate = newVector
            self.timestamp = newTimestamp
            covariance = measurementVariance
            return newVector
        }
        
        guard estimate.count == newVector.count else {
            return nil
        }
        
        // Increase the covariance linearly with time (to represent the decay in the accuracy of the previous measurement)
        let interval = newTimestamp.timeIntervalSince(timestamp)
        if interval > 0 {
            covariance += interval * sigma * sigma
        }
        
        // Smooth the input location to estimate the current location
        let kalmanGain = covariance / (covariance + measurementVariance)
        let filteredVector = zip(estimate, newVector).compactMap({ $0 + kalmanGain * ($1 - $0) })
        
        self.estimate = filteredVector
        self.timestamp = newTimestamp
        covariance = (1 - kalmanGain) * covariance
        
        return filteredVector
    }
    
    func reset() {
        covariance = 0.0
        estimate = nil
        timestamp = nil
    }
    
}
