//
//  CalloutSettingsCellView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol CalloutSettingsCellViewDelegate: AnyObject {
    func onCalloutSettingChanged(_ type: CalloutSettingCellType)
}

internal enum CalloutSettingCellType {
    case all, poi, mobility, beacon
}

class CalloutSettingsCellView: UITableViewCell {
    
    weak var delegate: CalloutSettingsCellViewDelegate?
    
    var type: CalloutSettingCellType! {
        didSet {
            guard let type = type, let settingSwitch = self.accessoryView as? UISwitch else {
                return
            }
            
            // Update the switch
            settingSwitch.isEnabled = type == .all || SettingsContext.shared.automaticCalloutsEnabled
            
            switch type {
            case .all:
                settingSwitch.isOn = SettingsContext.shared.automaticCalloutsEnabled
                return
            case .poi:
                settingSwitch.isOn = SettingsContext.shared.placeSenseEnabled
                return
            case .mobility:
                settingSwitch.isOn = SettingsContext.shared.mobilitySenseEnabled
                return
            case .beacon:
                settingSwitch.isOn = SettingsContext.shared.destinationSenseEnabled
                return
            }
        }
    }
    
    @IBAction func onSettingValueChanged(_ sender: Any) {
        guard let type = type, let settingSwitch = self.accessoryView as? UISwitch else {
            return
        }
        
        defer {
            delegate?.onCalloutSettingChanged(type)
        }
        
        let isOn = settingSwitch.isOn
        
        let log: ([String]) -> Void = { (categories: [String]) in
            for category in categories {
                GDLogActionInfo("Toggled \(category) callouts to: \(isOn)")
                
                GDATelemetry.track("settings.autocallouts_\(category)", value: isOn.description)
            }
        }
        
        switch type {
        case .all:
            SettingsContext.shared.automaticCalloutsEnabled = isOn
            GDATelemetry.track("settings.allow_callouts", value: isOn.description)
            return
            
        case .poi:
            // Places, Landmark, and Information Senses
            SettingsContext.shared.placeSenseEnabled = isOn
            SettingsContext.shared.landmarkSenseEnabled = isOn
            SettingsContext.shared.informationSenseEnabled = isOn
            log(["places", "landmarks", "info"])
            return
            
        case .mobility:
            // Mobility, Safety, and Intersection Sense
            SettingsContext.shared.mobilitySenseEnabled = isOn
            SettingsContext.shared.safetySenseEnabled = isOn
            SettingsContext.shared.intersectionSenseEnabled = isOn
            log(["mobility", "safety", "intersections"])
            return
            
        case .beacon:
            // Destination sense
            SettingsContext.shared.destinationSenseEnabled = isOn
            log(["destination"])
            return
        }
    }
}
