//
//  MarkerTableViewCellConfigurator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import UIKit

class MarkerTableViewCellConfigurator: TableViewCellConfigurator {
    
    typealias TableViewCell = POITableViewCell
    typealias Model = ReferenceEntity
    
    // MARK: Properties
    
    private var poiCellConfigurator: POITableViewCellConfigurator
    
    var location: CLLocation? {
        didSet {
            guard oldValue != location else {
                return
            }
            
            poiCellConfigurator.location = location
        }
    }
    
    var accessibilityActionDelegate: LocationAccessibilityActionDelegate? {
        didSet {
            poiCellConfigurator.accessibilityActionDelegate = accessibilityActionDelegate
        }
    }
    
    // MARK: Initialization
    
    init() {
        self.poiCellConfigurator = POITableViewCellConfigurator()
    }
    
    // MARK: `TableViewCellConfigurator`
    
    func configure(_ cell: POITableViewCell, forDisplaying model: ReferenceEntity) {
        // Use the default configuration for a POI
        poiCellConfigurator.configure(cell, forDisplaying: model.getPOI())
        
        if model.isNew {
            // If the marker is new, add the appropriate accessibility label
            // and image view
            cell.titleLabel.accessibilityLabel = GDLocalizedString("markers.new_badge.acc_label", model.name)
            cell.imageViewType = .new
        } else {
            cell.titleLabel.accessibilityLabel = model.name
            cell.imageViewType = .none
        }
    }
    
}
