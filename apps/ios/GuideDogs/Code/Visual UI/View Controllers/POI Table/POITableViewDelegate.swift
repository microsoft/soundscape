//
//  POITableViewDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol POITableViewController: AnyObject {
    var delegate: POITableViewDelegate? { get set }
    var onDismissPreviewHandler: (() -> Void)? { get set }
}

protocol POITableViewDelegate: AnyObject {
    
    // MARK: Properties
    
    var poiAccessibilityHint: String { get }
    var allowCurrentLocation: Bool { get }
    var allowMarkers: Bool { get }
    /// A string representing the use of the delegate, i.e. "beacons", "markers".
    var usageLog: String { get }
    /// Set `isCachingRequired = true` if a selected location result will
    /// be cached on device
    /// Location data can only be cached when an unencumbered coordinate is available
    var isCachingRequired: Bool { get }
    /// Set `true` to add a done button which will dismiss
    /// the view - Only use this property when the search views are
    /// presented modally!
    var doneNavigationItem: Bool { get }
    
    // MARK: Methods
    
    /// Informs the delegate object when the user selects a particular POI
    ///
    /// - Parameter poi: The POI the user selected
    func didSelect(poi: POI)
    
    /// Informs the delegate object when the user selects the "Use Current Location" option
    /// in the POI Table
    ///
    /// - Parameters:
    ///   - location: The location at which the user was located when they selected the "Use Current Location" row
    ///   - address: The reverse geocoded address of that location if it could be obtained, nil otherwise
    func didSelect(currentLocation location: CLLocation)
    
}
