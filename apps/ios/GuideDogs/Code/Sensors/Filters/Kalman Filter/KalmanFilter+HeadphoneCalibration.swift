//
//  KalmanFilter+HeadphoneCalibration.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension KalmanFilter {
    
    func process(calibration: HeadphoneCalibration) -> HeadphoneCalibration {
        let vector = [sin(calibration.valueInRadians), cos(calibration.valueInRadians)]
        let timestamp = calibration.timestamp
        let accuracy = calibration.accuracy
        
        guard let filteredVector = process(newVector: vector, newTimestamp: timestamp, newAccuracy: accuracy) else {
            return calibration
        }
        
        guard filteredVector.count == 2 else {
            return calibration
        }
        
        let filteredValueInRadians = atan2(filteredVector[0], filteredVector[1])
        let filteredValue = CircularQuantity(valueInRadians: filteredValueInRadians).normalized()
        
        return HeadphoneCalibration(value: filteredValue, accuracy: calibration.accuracy, timestamp: calibration.timestamp)
    }
    
}
