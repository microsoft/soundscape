//
//  CalibratableDevice.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

enum DeviceCalibrationState: Int {
    case needsCalibrating
    case calibrating
    case calibrated
}

protocol CalibratableDevice: Device {
    var calibrationState: DeviceCalibrationState { get }
    var calibrationOverriden: Bool { get set }
}
