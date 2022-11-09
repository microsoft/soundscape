//
//  DeviceManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine
import CocoaLumberjackSwift

extension Notification.Name {
    static let ARHeadsetCalibrationDidStart = Notification.Name("ARHeadsetCalibrationDidStart")
    static let ARHeadsetCalibrationUpdated = Notification.Name("ARHeadsetCalibrationUpdated")
    static let ARHeadsetCalibrationDidFinish = Notification.Name("ARHeadsetCalibrationDidFinish")
    static let ARHeadsetCalibrationCancelled = Notification.Name("ARHeadsetCalibrationCancelled")
    static let ARHeadsetDidConnect = Notification.Name("ARHeadsetDidConnect")
}

protocol DeviceManagerDelegate: AnyObject {
    func didConnectDevice(_ device: Device)
    func didDisconnectDevice(_ device: Device)
}

protocol DeviceManagerProtocol: AnyObject {
    var devices: [Device] { get }
}

class DeviceManager: DeviceManagerProtocol {

    weak var delegate: DeviceManagerDelegate?
    
    let geolocationManager: GeolocationManager
    
    var hasStoredDevices: Bool {
        let storedDevicesJSON = DeviceManager.storedDevicesJSON()
        return storedDevicesJSON.count > 0
    }
    
    var devices: [Device] = []
    
    private var isDeviceConnected: Bool {
        return devices.contains(where: { $0.isConnected })
    }
    
    init(geolocationManager: GeolocationManager) {
        self.geolocationManager = geolocationManager
    }
    
    func loadAndConnectDevices() {
        // Don't try to connect if we already have a connected device
        guard !isDeviceConnected else {
            return
        }
        
        // Only try to load stored devices if we haven't already done it
        if devices.isEmpty {
            devices = DeviceManager.storedDevices()
        }
        
        for device in devices {
            device.deviceDelegate = self
            device.connect()
        }
    }
    
    func add(device: Device) {
        if FirstUseExperience.didComplete(.addDevice(device: device.type)) == false {
            // User defaults tracks which devices have been previously
            // connected to Soundscape
            FirstUseExperience.setDidComplete(for: .addDevice(device: device.type))
        }
        
        device.deviceDelegate = self
        devices.append(device)
        
        if let device = device as? HeadphoneMotionManagerWrapper {
            if device.status.value == .calibrated {
                // Do not add `HeadphoneMotionManager` until the device
                // has finished initial calibration
                geolocationManager.add(device)
            }
        } else if let device = device as? UserHeadingProvider {
            // All other devices are ready for use
            geolocationManager.add(device)
        }
        
        DeviceManager.store(device: device)
        
        GDATelemetry.track("ar_headset.added", with: ["type": device.type.rawValue])
    }
    
    func remove(device: Device) {
        // Make sure the devices contain the device we want to remove
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else {
            DDLogError("[Device Manager] Could not remove device with id '\(device.id)', name '\(device.name)'")
            return
        }
        
        // Remove from memory
        devices.remove(at: index)
        
        // Remove from persistent storage
        DeviceManager.delete(device: device)
        
        // It's possible that the `HeadphoneMotionManager` is enabled but not has not connected
        // or initialized yet. Call `disconnect` to disable `HeadphoneMotionManager`
        if device.isConnected || device is HeadphoneMotionManagerWrapper {
            // Calling disconnect() will result in didDisconnectDevice(_:) getting called, resulting in the device being removed from the geolocation manager
            device.disconnect()
        }
        
        device.deviceDelegate = nil
        
        GDATelemetry.track("ar_headset.removed", with: ["type": device.type.rawValue])
    }
    
}

extension DeviceManager: DeviceDelegate {
    
    func didConnectDevice(_ device: Device) {
        if let userHeadingProvider = device as? UserHeadingProvider {
            geolocationManager.add(userHeadingProvider)
        }
        
        delegate?.didConnectDevice(device)
        
        GDATelemetry.track("ar_headset.connected", with: ["type": device.type.rawValue])
    }
    
    func didFailToConnectDevice(_ device: Device, error: DeviceError) {
        // Intentional no-op
    }
    
    func didDisconnectDevice(_ device: Device) {
        if let userHeadingProvider = device as? UserHeadingProvider {
            geolocationManager.remove(userHeadingProvider)
        }
        
        delegate?.didDisconnectDevice(device)
        
        GDATelemetry.track("ar_headset.disconnect", with: ["type": device.type.rawValue])
    }
    
}

fileprivate extension DeviceManager {
    
    private static var persistedDevicesURL: URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            DDLogError("[Device Manager] Could not access the documents directory")
            return nil
        }
        
        return documents.appendingPathComponent("PariedExternalDevice.json")
    }
    
    static func storedDevices() -> [Device] {
        let storedDevicesJSON = storedDevicesJSON()
        return storedDevicesJSON.compactMap { DeviceManager.device(from: $0) }
    }
    
    private static func storedDevicesJSON() -> [[String: Any]] {
        guard let url = DeviceManager.persistedDevicesURL, FileManager.default.fileExists(atPath: url.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: url)
            
            guard let devicesJSON = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                DDLogError("[Device Manager] Failed to serialize devices JSON data")
                return []
            }
            
            return devicesJSON
        } catch {
            DDLogError("[Device Manager] Error loading devices: \(error.localizedDescription)")
            return []
        }
    }
    
    @discardableResult
    static func store(device: Device) -> Bool {
        var devices = DeviceManager.storedDevices()
        
        // Don't add the same device twice
        guard !devices.contains(where: { $0.id == device.id }) else {
            return false
        }
        
        devices.append(device)
        
        return store(devices: devices)
    }
    
    @discardableResult
    static func store(devices: [Device]) -> Bool {
        guard let url = DeviceManager.persistedDevicesURL else { return false }

        let json = devices.compactMap { $0.dictionaryRepresentation }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            try data.write(to: url)
        } catch {
            DDLogError("[Device Manager] Error writing devices: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    @discardableResult
    static func delete(device: Device) -> Bool {
        var devices = DeviceManager.storedDevices()
        
        // Make sure the devices contain the device we want to remove
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else {
            DDLogError("[Device Manager] Could not delete device with id '\(device.id)', name '\(device.name)'")
            return false
        }
        devices.remove(at: index)
        
        return store(devices: devices)
    }
    
}

extension DeviceManager {
    static func device(from dictionary: [String: Any]) -> Device? {
        guard let type = dictionary["type"] as? String, let deviceType = DeviceType(rawValue: type) else { return nil }
        guard let id = dictionary["id"] as? String, let uuid = UUID(uuidString: id) else { return nil }
        guard let name = dictionary["name"] as? String else { return nil }
        
        switch deviceType {
        case .apple:
            return HeadphoneMotionManagerWrapper(id: uuid, name: name)
        }
    }
}
