//
//  TelemetrySettingsTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class TelemetrySettingsTableViewCell: UITableViewCell {

    weak var parent: UIViewController?
    
    var telemetrySwitch: UISwitch? {
        return accessoryView as? UISwitch
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        telemetrySwitch?.isOn = !SettingsContext.shared.telemetryOptout
    }

    @IBAction func onSettingValueChanged(_ sender: Any) {
        let prevOptedOut = SettingsContext.shared.telemetryOptout
        
        if prevOptedOut {
            GDATelemetry.enabled = true
            GDATelemetry.track("settings.telemetry_optout", value: String(false))
        } else {
            let alert = UIAlertController(title: GDLocalizedString("settings.telemetry.optout.alert_title"),
                                          message: GDLocalizedString("settings.telemetry.optout.alert_message"),
                                          preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: { [weak self] (_) in
                // User canceled, switch back
                self?.telemetrySwitch?.setOn(true, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: GDLocalizedString("settings.telemetry.optout.action"), style: .destructive, handler: { _ in
                // Send a "user opted-out" event before opting-out
                GDATelemetry.track("settings.telemetry_optout", value: String(true))
                GDATelemetry.enabled = false
            }))
            
            parent?.present(alert, animated: true, completion: nil)
        }
    }

}
