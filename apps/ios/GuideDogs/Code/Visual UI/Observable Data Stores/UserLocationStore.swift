//
//  UserLocationStore.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Combine
import CoreLocation

class UserLocationStore: ObservableObject {
    @Published var location: CLLocation?
    
    private var listener: AnyCancellable?
    
    init() {
        listener = NotificationCenter.default.publisher(for: .locationUpdated).sink { [weak self] notification in
            guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
                return
            }
            
            self?.location = location
        }
        
        // Save initial value
        self.location = AppContext.shared.geolocationManager.location
    }
    
    init(designValue: CLLocation) {
        location = designValue
    }
    
    deinit {
        listener?.cancel()
        listener = nil
    }
}
