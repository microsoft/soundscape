//
//  CompositeHeadphoneCalibrator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class CompositeHeadphoneCalibrator: ComponentHeadphoneCalibrator {
    
    // MARK: Properties
    
    private(set) var isActive = false
    private var calibrators: [ComponentHeadphoneCalibrator] = []
    private var filter = KalmanFilter(sigma: 1.0)
    
    // MARK: Initialization
    
    init() {
        // Initialize calibrators
        calibrators = [.device, .course].map({ return HeadphoneCalibrator(nSamples: 200, referenceHeadingType: $0) })
    }
    
    // MARK: `ComponentHeadphoneCalibrator`
    
    func startCalibrating() {
        guard isActive == false else {
            return
        }
        
        // Reset Kalman filter
        filter.reset()
        
        // Start calibrators
        calibrators.forEach({ $0.startCalibrating() })
        
        // Update state
        isActive = true
    }
    
    func stopCalibrating() {
        guard isActive else {
            return
        }
        
        // Update state
        isActive = false
        
        // Stop calibrators
        calibrators.forEach({ $0.stopCalibrating() })
        
        // Reset Kalman filter
        filter.reset()
    }
    
    func process(yawInDegrees: Double) -> HeadphoneCalibration? {
        guard isActive else {
            return nil
        }
        
        var estimatedCalibration: HeadphoneCalibration?
        
        calibrators.forEach({
            guard let calibration = $0.process(yawInDegrees: yawInDegrees) else {
                return
            }
            
            // Save the new calibration
            estimatedCalibration = filter.process(calibration: calibration)
            
            GDLogHeadphoneMotionInfo("calibrator { \($0) } - completed calibration: \(calibration.valueInDegrees), estimated: \(estimatedCalibration?.valueInDegrees ?? -1)")
        })
        
        return estimatedCalibration
    }
    
}
    
