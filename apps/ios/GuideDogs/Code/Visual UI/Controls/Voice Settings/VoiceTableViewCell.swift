//
//  VoiceTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation

extension VoiceTableViewCell {
    struct PrototypeCell {
        static let standard = ( nib: "VoiceTableViewCell", id: "VoiceCell" )
        static let accessibility = ( nib: "AccessibilityVoiceTableViewCell", id: "AccessibilityVoiceCell" )
        static let firstLaunch = ( nib: "FirstLaunchVoiceTableViewCell", id: "FirstLaunchVoiceCell" )
    }
}

class VoiceTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    private weak var delegate: VoiceTableViewCellDelegate?
    private(set) var voice: AVSpeechSynthesisVoice?
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var checkImageView: UIImageView?
    
    // MARK: Initialization
    
    func initialize(voice: AVSpeechSynthesisVoice, delegate: VoiceTableViewCellDelegate? = nil) {
        self.delegate = delegate
        self.voice = voice
        
        let isSelected = (voice.identifier == SettingsContext.shared.voiceId)

        // If cell is already selected, disable selection
        self.selectionStyle = isSelected ? .none : .default
        
        // `Jess`
        let voiceName = GDLocalizationUnnecessary(voice.name)
        
        // `English (United Kingdom) or `Default, English (United Kingdom)`
        let subtitle = voice.language
        
        // Initialize view
        self.titleLabel.text = voiceName
        self.subtitleLabel.text = subtitle
        self.checkImageView?.isHidden = !isSelected
        
        // "Jess, English (United Kingdom)"
        let accessibilityStr = GDLocalizedString("voice.title.voice_name_and_locale", voiceName, subtitle)
        
        // or "Jess, English (United Kingdom), Selected."
        let selectedAccessibilityStr = GDLocalizedString("voice.title.voice_name_and_locale_selected", voiceName, subtitle)
        
        // Initialize accessibility view
        self.accessibilityLabel = isSelected ? selectedAccessibilityStr : accessibilityStr
        
        self.accessibilityHint = isSelected ? GDLocalizedString("voice.voice_cell.selected.acc_hint") : GDLocalizedString("voice.voice_cell.use.acc_hint")
        
        // Add custom actions
        self.accessibilityCustomActions = [
            // Add `preview` action
            UIAccessibilityCustomAction(name: GDLocalizedString("voice.action.preview"), target: self, selector: #selector(onPreviewButtonTouchUpInside))
        ]
    }
    
    // MARK: Actions
    
    @IBAction func onPreviewButtonTouchUpInside() {
        guard let voice = voice else {
            return
        }
        
        delegate?.didSelectPreview(voice: voice)
    }
    
}
