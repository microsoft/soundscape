//
//  UnitsOfMeasureTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class UnitsOfMeasureTableViewCell: UITableViewCell, NibLoadableView {

    @IBOutlet weak var unitsSegmentedControl: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        
        unitsSegmentedControl.setTitle(GDLocalizedString("settings.units.imperial"), forSegmentAt: 0)
        unitsSegmentedControl.setTitle(GDLocalizedString("settings.units.metric"), forSegmentAt: 1)
        
        unitsSegmentedControl.selectedSegmentIndex = (SettingsContext.shared.metricUnits == true) ? 1 : 0
        
        // Setup appearance
        unitsSegmentedControl.backgroundColor = Colors.Background.primary
        unitsSegmentedControl.selectedSegmentTintColor = Colors.Foreground.primary
        
        if let color = Colors.Background.tertiary {
            unitsSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: color], for: .selected)
        }
        
        if let color = Colors.Foreground.primary {
            unitsSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: color], for: .normal)
        }
    }

    @IBAction func unitsValuedChanged(_ sender: UISegmentedControl) {
        SettingsContext.shared.metricUnits = (sender.selectedSegmentIndex == 1)
        
        GDATelemetry.track("settings.units_of_measure", with: ["units": SettingsContext.shared.metricUnits ? "metric" : "imperial"])
    }
}
