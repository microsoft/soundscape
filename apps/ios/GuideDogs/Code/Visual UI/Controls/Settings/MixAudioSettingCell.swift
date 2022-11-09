//
//  MixAudioSettingCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol MixAudioSettingCellDelegate: AnyObject {
    func onSettingValueChanged(_ cell: MixAudioSettingCell, settingSwitch: UISwitch)
}

class MixAudioSettingCell: UITableViewCell {
    
    weak var delegate: MixAudioSettingCellDelegate?
    
    var settingSwitch: UISwitch? {
        return accessoryView as? UISwitch
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        settingSwitch?.isOn = !SettingsContext.shared.audioSessionMixesWithOthers
        settingSwitch?.isEnabled = AppContext.shared.eventProcessor.activeBehavior as? RouteGuidance == nil
    }

    @IBAction func onSettingValueChanged(_ sender: Any) {
        guard let settingSwitch = self.accessoryView as? UISwitch else { return }
        
        delegate?.onSettingValueChanged(self, settingSwitch: settingSwitch)
    }

}
