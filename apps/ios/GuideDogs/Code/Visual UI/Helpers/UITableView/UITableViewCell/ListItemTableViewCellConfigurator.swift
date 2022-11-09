//
//  ListItemTableViewCellConfigurator.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import UIKit
import CoreLocation

class ListItemTableViewCellConfigurator: TableViewCellConfigurator {
    
    typealias TableViewCell = POITableViewCell
    typealias Model = ListItem
    
    struct ListItem {
        let item: POI
        // `nil` if position information will not be included
        // in accessibility hint
        let index: Int?
        let count: Int?
        
        init(item: POI) {
            self.item = item
            index = nil
            count = nil
        }
        
        init(item: POI, index: Int, count: Int) {
            self.item = item
            self.index = index
            self.count = count
        }
    }
    
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
    
    func configure(_ cell: POITableViewCell, forDisplaying model: ListItem) {
        // Use the default configuration for a POI
        poiCellConfigurator.configure(cell, forDisplaying: model.item)
        
        // Append the POI's index within it's list to the end of the accessibility hint
        if let index = model.index, let count = model.count, let accessibilityLabel = cell.computedAccessibilityLabel {
            let indexString = GDLocalizedString("settings.new_feature.num_of_num", String(index), String(count))
            cell.accessibilityLabel = "\(accessibilityLabel), \(indexString)"
        }
    }
    
}

private extension UILabel {
    
    var computedAccessibilityLabel: String? {
        return accessibilityLabel ?? text
    }
    
}

private extension POITableViewCell {
    
    var computedAccessibilityLabel: String? {
        var accessibility = titleLabel.computedAccessibilityLabel ?? ""

        let subtitle = subtitleLabel.computedAccessibilityLabel
        let detail = detailLabel.computedAccessibilityLabel
        
        if let subtitle = subtitle {
            accessibility.append(". \(subtitle)")
        }
        
        if let detail = detail {
            accessibility.append(". \(detail)")
        }
        
        return accessibility
    }
    
}
