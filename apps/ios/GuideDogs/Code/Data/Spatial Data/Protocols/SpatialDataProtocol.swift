//
//  SpatialDataProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import CoreLocation

protocol SpatialDataProtocol: AnyObject {
    // MARK: Read-only static properties
    
    static var zoomLevel: UInt { get }
    static var cacheDistance: CLLocationDistance { get }
    static var initialPOISearchDistance: CLLocationDistance { get }
    static var expansionPOISearchDistance: CLLocationDistance { get }
    static var refreshTimeInterval: TimeInterval { get }
    static var refreshDistanceInterval: CLLocationDistance { get }
    
    // MARK: Properties
    
    var motionActivityContext: MotionActivityProtocol { get }
    var destinationManager: DestinationManagerProtocol { get }
    var state: SpatialDataState { get }
    var loadedSpatialData: Bool { get }
    var currentTiles: [VectorTile] { get }
    
    // MARK: Methods
    
    func start()
    func stop()
    func clearCache() -> Bool
    func getDataView(for location: CLLocation, searchDistance: CLLocationDistance) -> SpatialDataViewProtocol?
    func getCurrentDataView(searchDistance: CLLocationDistance) -> SpatialDataViewProtocol?
    func getCurrentDataView(initialSearchDistance: CLLocationDistance, shouldExpandDataView: @escaping (SpatialDataViewProtocol) -> Bool) -> SpatialDataViewProtocol?
    func updateSpatialData(at location: CLLocation, completion: @escaping () -> Void) -> Progress?
}
