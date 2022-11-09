//
//  HeadphoneCalibrator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

class HeadphoneCalibrator: ComponentHeadphoneCalibrator {
    
    private struct Sample: CustomStringConvertible {
        
        let yaw: CircularQuantity
        let heading: CircularQuantity
        
        init(headingInDegrees: Double, yawInDegrees: Double) {
            yaw = CircularQuantity(valueInDegrees: yawInDegrees).normalized()
            heading = CircularQuantity(valueInDegrees: headingInDegrees).normalized()
        }
        
        // MARK: `ComponentHeadphoneCalibrator`
        
        public var description: String {
            return "yaw: \(yaw) heading: \(heading)"
        }
        
    }
    
    // MARK: Properties
    
    private(set) var isActive = false
    private let nSamples: Int
    private let referenceHeadingType: HeadingType
    private var samples: [Sample] = []
    private var headingObserver: Heading?
    // `headingInDegrees` is read from `process(yawInDegrees:)` and is
    // written to from `headingObserver`
    private var headingInDegrees = ThreadSafeValue<Double>(qos: .userInitiated)
    // `.developerTools`
    private var verboseLoggingCount = 200
    
    // MARK: Initialization
    
    init(nSamples: Int, referenceHeadingType: HeadingType) {
        self.nSamples = nSamples
        self.referenceHeadingType = referenceHeadingType
    }
    
    // MARK: `ComponentHeadphoneCalibrator`
    
    func startCalibrating() {
        guard isActive == false else {
            return
        }
        
        // Create a heading observer
        headingObserver = AppContext.shared.geolocationManager.heading(orderedBy: [referenceHeadingType])
        
        // Initialize heading and samples
        headingInDegrees.value = headingObserver?.value
        samples = []
        
        // Start heading updates
        headingObserver?.onHeadingDidUpdate { [weak self] (newValue) in
            guard let `self` = self else {
                return
            }
            
            if let newHeading = newValue?.value {
                // Save new value
                self.headingInDegrees.value = newHeading
            } else {
                // Heading is invalid
                self.headingInDegrees.value = nil
            }
        }
        
        // Update state
        isActive = true
    }
    
    func stopCalibrating() {
        guard isActive else {
            return
        }
        
        // Update state
        isActive = false
        
        // Stop heading updates
        headingObserver?.onHeadingDidUpdate(nil)
        
        // Reset heading and samples
        headingInDegrees.value = nil
        samples = []
    }
    
    func process(yawInDegrees: Double) -> HeadphoneCalibration? {
        guard isActive else {
            return nil
        }
        
        if FeatureFlag.isEnabled(.developerTools) {
            guard DebugSettingsContext.shared.isCalibrationEnabled(type: referenceHeadingType) else {
                // Calibration has been disabled
                return nil
            }
        }
        
        guard let headingInDegrees = headingInDegrees.value else {
            // If there is no known heading, reset the calibration
            // and return
            samples = []
            return nil
        }
        
        let newValue = Sample(headingInDegrees: headingInDegrees, yawInDegrees: yawInDegrees)
        samples.append(newValue)
        
        guard samples.count > nSamples else {
            // Calibration is not complete
            // Additional samples are required
            return nil
        }
        
        // Do not maintain more than `nSamples`
        samples.removeFirst()
        
        // To calibrate, the sample set should have a standard deviation less than
        // `stdevMax`
        let stdevMax = 10.0
        let differences = samples.compactMap({ return $0.heading - $0.yaw })
        
        guard let stdev = differences.stdevInDegrees(), stdev < stdevMax else {
            // `verboseLoggingCount` ensures that we don't log too often
            if verboseLoggingCount >= 200 {
                // [CMH] verbose logging for is enbabled via debug settings
                GDLogHeadphoneMotionVerbose("calibrator { \(referenceHeadingType) } - stdev > 10.0 - stdev: \(differences.stdevInDegrees() ?? -1)")
                GDLogHeadphoneMotionVerbose("calibrator { \(referenceHeadingType) } - stdev > 10.0 - samples: \(samples)")
                
                // Reset count
                verboseLoggingCount = 0
            } else {
                verboseLoggingCount += 1
            }
            
            // Standard deviation is too large
            return nil
        }
        
        guard let mean = differences.mean() else {
            // Failed to calculate mean
            return nil
        }
        
        // [CMH] verbose logging for is enbabled via debug settings
        GDLogHeadphoneMotionVerbose("calibrator { \(referenceHeadingType) } - completed calibration: \(mean) - samples: \(samples)")
        
        // Reset calibration after it completes
        samples = []
        
        // Calculate the offset between the average yaw and
        // average heading
        return HeadphoneCalibration(value: mean, accuracy: stdev, timestamp: Date())
    }
    
}

extension HeadphoneCalibrator: CustomStringConvertible {
    
    var description: String {
        return "\(referenceHeadingType)"
    }
    
}

private extension DebugSettingsContext {
    
    func isCalibrationEnabled(type: HeadingType) -> Bool {
        guard FeatureFlag.isEnabled(.developerTools) else {
            return true
        }
        
        switch type {
        case .device: return DebugSettingsContext.shared.isHeadphoneMotionDeviceHeadingEnabled
        case .course: return DebugSettingsContext.shared.isHeadphoneMotionCourseEnabled
        default: return false
        }
    }
    
}
