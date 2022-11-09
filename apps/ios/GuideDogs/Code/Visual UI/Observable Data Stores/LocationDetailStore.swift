//
//  LocationDetailStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

class LocationDetailStore: ObservableObject {
    
    // MARK: Properties
    
    @Published private(set) var detail: LocationDetail
    
    private var markerId: String?
    private var beaconId: String?
    private var listeners: [AnyCancellable] = []
    
    // MARK: Initialization
    
    init(detail: LocationDetail) {
        self.detail = detail
        self.markerId = detail.markerId
        self.beaconId = detail.beaconId
        
        listeners.append(NotificationCenter.default.publisher(for: .markerAdded).sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            guard self.markerId != detail.markerId else {
                // No change
                return
            }
            
            // Save change
            self.markerId = detail.markerId
            
            // Publish update
            self.objectWillChange.send()
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .markerUpdated).sink(receiveValue: { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            if self.markerId != detail.markerId {
                // Save change
                self.markerId = detail.markerId
                
                // Publish update
                self.objectWillChange.send()
            } else {
                guard let markerId = notification.userInfo?[ReferenceEntity.Keys.entityId] as? String else {
                    return
                }
                
                guard self.markerId == markerId else {
                    return
                }
                
                // Publish update
                self.objectWillChange.send()
            }
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .markerRemoved).sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            guard self.markerId != detail.markerId else {
                // No change
                return
            }
            
            // Save change
            self.markerId = detail.markerId
            
            // Publish update
            self.objectWillChange.send()
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .destinationChanged).sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            guard self.beaconId != detail.beaconId else {
                // No change
                return
            }
            
            // Save change
            self.beaconId = detail.beaconId
            
            // Publish update
            self.objectWillChange.send()
        }))
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
    // MARK: Wrapper
    
    func fetchNameAndAddressIfNeeded() {
        LocationDetail.fetchNameAndAddressIfNeeded(for: detail) { [weak self] newValue in
            guard let `self` = self else {
                return
            }
            
            self.detail = newValue
        }
    }
    
}
