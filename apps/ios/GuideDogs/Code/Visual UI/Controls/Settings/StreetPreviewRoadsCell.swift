//
//  StreetPreviewRoadsCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class StreetPreviewRoadsCell: UITableViewCell {
    
    var settingSwitch: UISwitch? {
        return accessoryView as? UISwitch
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        settingSwitch?.isOn = SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads
    }

    @IBAction func onSettingValueChanged(_ sender: Any) {
        guard let settingSwitch = self.accessoryView as? UISwitch else {
            return
        }
        
        SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads = settingSwitch.isOn
        
        GDATelemetry.track("preview.include_unnamed_roads", with: ["value": "\(SettingsContext.shared.previewIntersectionsIncludeUnnamedRoads)", "context": "app_settings"])
    }

}
