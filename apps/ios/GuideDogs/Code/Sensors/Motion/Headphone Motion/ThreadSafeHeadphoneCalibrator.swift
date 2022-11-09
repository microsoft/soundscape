//
//  ThreadSafeHeadphoneCalibrator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

//
// This class wraps the access methods for the given `ComponentHeadphoneCalibrator`
// in a thread-safe, concurrent queue
//
// Read access (e.g., `isActive`) is done synchronously
// Write access (e.g., start, stop and process methods) is done asynchronously with a barrier
//
struct ThreadSafeHeadphoneCalibrator {
    
    // MARK: Properties
    
    private let queue: DispatchQueue
    private let calibrator: ComponentHeadphoneCalibrator
    
    var isActive: Bool {
        var isActive = false
        
        // Read synchronously
        queue.sync {
            isActive = calibrator.isActive
        }
        
        return isActive
    }
    
    // MARK: Initialization
    
    init(_ calibrator: ComponentHeadphoneCalibrator, qos: DispatchQoS) {
        // Save calibrator
        self.calibrator = calibrator
        
        // Initialize queue
        queue = DispatchQueue(label: "com.company.appname.threadsafecalibrator", qos: qos, attributes: .concurrent)
    }
    
    // MARK: Multithreading
    
    func startCalibrating() {
        queue.async(flags: .barrier) {
            self.calibrator.startCalibrating()
        }
    }
    
    func stopCalibrating() {
        queue.async(flags: .barrier) {
            self.calibrator.stopCalibrating()
        }
    }
    
    func process(yawInDegrees: Double, completion: @escaping (HeadphoneCalibration?) -> Void) {
        queue.async(flags: .barrier) {
            let calibration = calibrator.process(yawInDegrees: yawInDegrees)
            completion(calibration)
        }
    }
    
}
