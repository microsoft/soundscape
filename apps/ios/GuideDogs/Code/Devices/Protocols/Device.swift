//
//  Device.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum DeviceError: Error {
    /// Indicates that the device's firmware needs to be updated before it can be connected
    case unsupportedFirmwareVersion
    /// Indicates that a connection error had occurred
    case failedConnection
    /// Indicates that a device becomes unavailable
    case unavailable
    /// Indicates that a user canceled the connection attempt
    case userCancelled
}

protocol DeviceDelegate: AnyObject {
    func didConnectDevice(_ device: Device)
    func didFailToConnectDevice(_ device: Device, error: DeviceError)
    func didDisconnectDevice(_ device: Device)
}

typealias DeviceCompletionHandler = (Result<Device, DeviceError>) -> Void

enum DeviceType: String, Codable, CaseIterable {
    case apple
}

extension DeviceType {
    
    // When applicable, define a reachability protocol for
    // supported devices.
    //
    // This protocol will be used to prompt the user to enable
    // head tracking when the device is reachable but not
    // connected in Soundscape
    var reachability: DeviceReachability? {
        switch self {
        case .apple: return HeadphoneMotionManagerReachabilityWrapper()
        }
    }
    
}

protocol Device: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var model: String { get }
    var type: DeviceType { get }
    var isConnected: Bool { get }
    var isFirstConnection: Bool { get }
    
    var deviceDelegate: DeviceDelegate? { get set }
    
    static func setupDevice(callback: @escaping DeviceCompletionHandler)

    func connect()
    func disconnect()
}

extension Device {
    var dictionaryRepresentation: [String: Any] {
        return ["id": id.uuidString,
                "name": name,
                "type": type.rawValue]
    }
}
