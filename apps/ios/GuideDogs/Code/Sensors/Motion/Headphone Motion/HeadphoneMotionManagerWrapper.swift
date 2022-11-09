//
//  HeadphoneMotionManagerWrapper.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

// `HeaphoneMotionManager` is only available iOS 14.4+
//
// This is a wrapper class which should be removed
// once support for iOS < 14.4 is removed
class HeadphoneMotionManagerWrapper {
    
    typealias UserHeadingDevice = UserHeadingProvider & Device
    
    // MARK: Properties
    
    private let headphoneMotionManager: UserHeadingDevice?
    private var subscriber: AnyCancellable?
    private(set) var status: CurrentValueSubject<HeadphoneMotionStatus, Never>
    // `UserHeadingProvider` delegate
    weak var headingDelegate: UserHeadingProviderDelegate?
    // `Device` delegate
    weak var deviceDelegate: DeviceDelegate?

    // MARK: Initialization
    
    convenience init() {
        if #available(iOS 14.4, *) {
            let manager = HeadphoneMotionManager()
            self.init(headphoneMotionManager: manager)
        } else {
            // `HeaphoneMotionManager` is not available on
            // iOS < 14.4
            self.init(headphoneMotionManager: nil)
        }
    }
    
    convenience init(id: UUID, name: String) {
        if #available(iOS 14.4, *) {
            let manager = HeadphoneMotionManager(id: id, name: name)
            self.init(headphoneMotionManager: manager)
        } else {
            // `HeaphoneMotionManager` is not available on
            // iOS < 14.4
            self.init(headphoneMotionManager: nil)
        }
    }
    
    private init(headphoneMotionManager: UserHeadingDevice?) {
        if #available(iOS 14.4, *), let headphoneMotionManager = headphoneMotionManager as? HeadphoneMotionManager {
            // Initialize headphone motion manager
            self.headphoneMotionManager = headphoneMotionManager
            
            // Initialize status
            let value = headphoneMotionManager.status.value
            self.status = .init(value)
            
            // Listen for and publish new values
            // of `status`
            subscriber = headphoneMotionManager.status
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] (newValue) in
                    guard let `self` = self else {
                        return
                    }
                    
                    // Update status
                    self.status.value = newValue
                })
        } else {
            // `CMHeadphoneMotionManager` is not available on
            // iOS < 14.4
            self.headphoneMotionManager = nil
            self.status = .init(.unavailable)
        }
        
        // After `self` has initialized, initialize delegates
        self.headphoneMotionManager?.headingDelegate = self
        self.headphoneMotionManager?.deviceDelegate = self
    }
    
}

extension HeadphoneMotionManagerWrapper: UserHeadingProvider {
    
    // MARK: Properties
    
    var id: UUID {
        headphoneMotionManager?.id ?? UUID()
    }
    
    var accuracy: Double {
        return headphoneMotionManager?.accuracy ?? 0.0
    }
    
    // MARK: User Heading Updates
    
    func startUserHeadingUpdates() {
        headphoneMotionManager?.startUserHeadingUpdates()
    }
    
    func stopUserHeadingUpdates() {
        headphoneMotionManager?.stopUserHeadingUpdates()
    }
    
}

extension HeadphoneMotionManagerWrapper: UserHeadingProviderDelegate {
    
    func userHeadingProvider(_ provider: UserHeadingProvider, didUpdateUserHeading heading: HeadingValue?) {
        headingDelegate?.userHeadingProvider(self, didUpdateUserHeading: heading)
    }
    
}

extension HeadphoneMotionManagerWrapper: Device {
    
    // MARK: Properties
    
    var name: String {
        headphoneMotionManager?.name ?? ""
    }
    
    var model: String {
        headphoneMotionManager?.model ?? GDLocalizationUnnecessary("Apple AirPods")
    }
    
    var type: DeviceType {
        headphoneMotionManager?.type ?? .apple
    }
    
    var isConnected: Bool {
        headphoneMotionManager?.isConnected ?? false
    }
    
    var isFirstConnection: Bool {
        headphoneMotionManager?.isFirstConnection ?? false
    }
    
    // MARK: Device
    
    static func setupDevice(callback: @escaping DeviceCompletionHandler) {
        if #available(iOS 14.4, *) {
            HeadphoneMotionManager.setupDevice { (result) in
                switch result {
                case .success(let device):
                    let manager = device as? HeadphoneMotionManager
                    let wrapper = HeadphoneMotionManagerWrapper(headphoneMotionManager: manager)
                    
                    callback(.success(wrapper))
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        } else {
            // `CMHeadphoneMotionManager` is not available on the device
            // e.g. Device is running iOS < 14.4
            callback(.failure(.unavailable))
        }
    }
    
    func connect() {
        headphoneMotionManager?.connect()
    }
    
    func disconnect() {
        headphoneMotionManager?.disconnect()
    }
    
}

extension HeadphoneMotionManagerWrapper: DeviceDelegate {
    
    func didConnectDevice(_ device: Device) {
        deviceDelegate?.didConnectDevice(self)
    }
    
    func didFailToConnectDevice(_ device: Device, error: DeviceError) {
        deviceDelegate?.didFailToConnectDevice(self, error: error)
    }
    
    func didDisconnectDevice(_ device: Device) {
        deviceDelegate?.didDisconnectDevice(self)
    }
    
}
