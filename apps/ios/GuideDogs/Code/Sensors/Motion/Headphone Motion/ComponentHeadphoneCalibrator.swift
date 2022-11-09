//
//  ComponentHeadphoneCalibrator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol ComponentHeadphoneCalibrator {
    var isActive: Bool { get }
    func startCalibrating()
    func stopCalibrating()
    func process(yawInDegrees: Double) -> HeadphoneCalibration?
}
