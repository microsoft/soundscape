//
//  HeadphoneCalibrationManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreMotion

class HeadphoneCalibrationManager {
    
    // MARK: Properties
    
    // `ThreadSafeHeadphoneCalibrator` schedules operations on a thread-safe queue
    private let calibrator = ThreadSafeHeadphoneCalibrator(CompositeHeadphoneCalibrator(), qos: .userInitiated)
    // `estimatedCalibration` is read from when processing `CMDeviceMotion` updates
    // and is written to when an asynchronous calibration completes
    private var estimatedCalibration = ThreadSafeValue<CircularQuantity>(qos: .userInitiated)
    // MARK: Headphone Calibration
    
    func startCalibrating() {
        guard calibrator.isActive == false else {
            return
        }
        
        // Initialize estimated calibration
        estimatedCalibration.value = nil
        
        // Start calibrator
        calibrator.startCalibrating()
    }
    
    func stopCalibrating() {
        guard calibrator.isActive else {
            return
        }
        
        // Stop calibrator
        calibrator.stopCalibrating()
        
        // Reset estimated calibration
        estimatedCalibration.value = nil
    }
    
    func heading(for deviceMotion: CMDeviceMotion) -> Double? {
        guard calibrator.isActive else {
            return nil
        }
        
        // Normalize the yaw value
        let yawInDegrees = 180 - deviceMotion.attitude.yaw.radiansToDegrees
        
        // Calibration occurs asynchronously via a thread-safe wrapper
        calibrator.process(yawInDegrees: yawInDegrees) { [weak self] (calibration) in
            guard let `self` = self else {
                return
            }
            
            if let newValue = calibration?.value {
                // Save the new calibration
                self.estimatedCalibration.value = newValue
            }
        }
        
        guard let offset = estimatedCalibration.value?.valueInDegrees else {
            // Initial calibration is not complete
            return nil
        }
        
        // [CMH] verbose logging for is enbabled via debug settings
        GDLogHeadphoneMotionVerbose("yaw: \(yawInDegrees), offset: \(offset), heading: \(fmod(yawInDegrees + offset, 360.0))")
        
        // Return the estimated heading
        return fmod(yawInDegrees + offset, 360.0)
    }
    
}
