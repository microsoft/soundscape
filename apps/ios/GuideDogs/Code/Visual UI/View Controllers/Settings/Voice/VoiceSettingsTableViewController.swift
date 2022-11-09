//
//  VoiceSettingsTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation
import Combine

protocol VoicesTableViewControllerDelegate: AnyObject {
    func onVoiceSelected(_ voice: AVSpeechSynthesisVoice)
}

class VoiceSettingsTableViewController: BaseTableViewController {
    
    struct Section {
        static let instructions = 0
        static let speakingRate = 1
        static let currentLanguage = 2
        static let otherLanguages = 3
    }
    
    struct Cell {
        static let downloadFromSettings = 0
    }
    
    // MARK: Properties
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    
    weak var delegate: VoicesTableViewControllerDelegate?
    
    private var didMuteCallouts: Bool = false
    private var didMuteBeacon: Bool = false
    
    private var initialDefaultIdentifier: String?
    private var currentVoiceIdentifier: String?
    private var currentVoiceIndex: IndexPath?
    private var previewingVoiceIdentifier: String?
    private var cancellable: AnyCancellable?
    
    private var voicesInCurrentLang: [AVSpeechSynthesisVoice] = []
    private var voicesInOtherLang: [AVSpeechSynthesisVoice] = []
    
    private let currentLocale = LocalizationContext.currentAppLocale
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let id = SettingsContext.shared.voiceId {
            if AVSpeechSynthesisVoice(identifier: id) == nil {
                // The user must have deleted a voice they previously downloaded... Reset the setting...
                SettingsContext.shared.voiceId = nil
                currentVoiceIdentifier = TTSConfigHelper.defaultVoice(forLocale: LocalizationContext.currentAppLocale)?.identifier
                initialDefaultIdentifier = currentVoiceIdentifier
            } else {
                currentVoiceIdentifier = id
                initialDefaultIdentifier = nil
            }
        } else {
            currentVoiceIdentifier = TTSConfigHelper.defaultVoice(forLocale: LocalizationContext.currentAppLocale)?.identifier
            initialDefaultIdentifier = currentVoiceIdentifier
        }
        
        updateVoiceState()
        
        // Enable automatic sizing
        tableView.estimatedRowHeight = 52.5
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 20
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        
        cancellable = NotificationCenter.default.publisher(for: .appWillEnterForeground).sink { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            if let id = SettingsContext.shared.voiceId, AVSpeechSynthesisVoice(identifier: id) == nil {
                // The user must have deleted a voice they previously downloaded... Reset the setting...
                SettingsContext.shared.voiceId = nil
                self.currentVoiceIdentifier = TTSConfigHelper.defaultVoice(forLocale: LocalizationContext.currentAppLocale)?.identifier
                self.initialDefaultIdentifier = self.currentVoiceIdentifier
            }
            
            self.updateVoiceState()
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.voice")
        
        if AppContext.shared.spatialDataContext.destinationManager.isAudioEnabled {
            didMuteBeacon = true
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio(false)
        }
        
        if SettingsContext.shared.automaticCalloutsEnabled {
            didMuteCallouts = true
            SettingsContext.shared.automaticCalloutsEnabled = false
            AppContext.shared.eventProcessor.hush(playSound: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if didMuteBeacon {
            AppContext.shared.spatialDataContext.destinationManager.toggleDestinationAudio(false)
        }
        
        if didMuteCallouts {
            SettingsContext.shared.automaticCalloutsEnabled = true
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.reloadData()
    }
    
    private func updateVoiceState() {
        voicesInCurrentLang = TTSConfigHelper.loadVoices(forCurrentLanguage: true, currentLocale: LocalizationContext.currentAppLocale)
        voicesInOtherLang = TTSConfigHelper.loadVoices(forCurrentLanguage: false, currentLocale: LocalizationContext.currentAppLocale)
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let locale = LocalizationContext.currentAppLocale
        
        switch section {
        case Section.speakingRate:
            return GDLocalizedString("voice.settings.speaking_rate")
            
        case Section.instructions:
            return nil
            
        case Section.currentLanguage:
            guard let lang = locale.languageCode else {
                return locale.localizedDescription
            }
            
            return locale.localizedString(forLanguageCode: lang)
            
        default:
            return GDLocalizedString("voice.apple.other_languages")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case Section.instructions:
            return "\(GDLocalizedString("whats_new.3_2_0.2.description")) \(GDLocalizedString("voice.apple.no_siri"))"
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.speakingRate:
            return 1
            
        case Section.instructions:
            return 0
            
        case Section.currentLanguage:
            return voicesInCurrentLang.count
            
        default:
            return voicesInOtherLang.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (Section.speakingRate, _):
            // Handle the rate cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "SpeakingRateCell", for: indexPath)
            
            if let rateCell = cell as? SpeakingRateTableViewCell {
                rateCell.initialize()
            }
            
            return cell
            
        case (Section.instructions, _):
            // Handle the instructions cell
            return tableView.dequeueReusableCell(withIdentifier: "VoiceInstructionsCell", for: indexPath)
            
        default:
            // Handle the voice cells
            let cell = tableView.dequeueReusableCell(withIdentifier: "VoiceCell", for: indexPath)
            let voice = indexPath.section == Section.currentLanguage ? voicesInCurrentLang[indexPath.row] : voicesInOtherLang[indexPath.row]
            
            cell.textLabel?.text = voice.name
            cell.detailTextLabel?.text = detail(for: voice, default: voice.identifier == initialDefaultIdentifier)
            cell.accessibilityHint = GDLocalizedString("voice.apple.preview_hint")
            
             if previewingVoiceIdentifier == voice.identifier {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = Colors.Foreground.primary
                spinner.startAnimating()
                cell.accessoryType = .none
                cell.accessoryView = spinner
                currentVoiceIndex = indexPath
            } else if currentVoiceIdentifier == voice.identifier {
                cell.accessoryView = nil
                cell.accessoryType = .checkmark
                currentVoiceIndex = indexPath
            } else {
                cell.accessoryView = nil
                cell.accessoryType = .none
            }
            
            return cell
        }
    }
    
    private func detail(for voice: AVSpeechSynthesisVoice, default isDefault: Bool) -> String {
        var detail = ""
        
        let voiceLocale = Locale(identifier: voice.language)
        if voiceLocale.languageCode != currentLocale.languageCode {
            detail = voiceLocale.localizedDescription
        } else if let region = voiceLocale.regionCode {
            detail = voiceLocale.localizedString(forRegionCode: region) ?? ""
        }
        
        return isDefault ? GDLocalizedString("voice.apple.default", detail).trimmingCharacters(in: .whitespaces) : detail
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let voice = indexPath.section == Section.currentLanguage ? voicesInCurrentLang[indexPath.row] : voicesInOtherLang[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // If this voice is currently selected, or is already an enhanced voice, just select it and play a sample
        guard voice.hasEnhancedVersion(), currentVoiceIdentifier != voice.identifier else {
            select(voice, at: indexPath)
            return
        }
        
        // If the user has selected the compact version of a downloaded premium voice, don't show the alert
        guard !voice.hasEnhancedVersionDownloaded() else {
            select(voice, at: indexPath)
            return
        }
        
        // Show an alert indicating that the user can download an enhanced version of the voice in Settings
        let alert = UIAlertController(title: GDLocalizedString("voice.settings.enhanced_available.title"),
                                      message: GDLocalizedString("voice.settings.enhanced_available"),
                                      preferredStyle: .alert)
        
        let enhancedAction = UIAlertAction(title: GDLocalizedString("voice.settings.enhanced_available.button"), style: .default) { [weak self] (_) in
            self?.select(voice, at: indexPath)
        }
        alert.addAction(enhancedAction)
        alert.preferredAction = enhancedAction
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func select(_ voice: AVSpeechSynthesisVoice, at indexPath: IndexPath) {
        initialDefaultIdentifier = nil
        previewingVoiceIdentifier = voice.identifier
        currentVoiceIdentifier = voice.identifier
        SettingsContext.shared.voiceId = voice.identifier
        
        AppContext.shared.eventProcessor.hush()
        
        refreshCells(previous: currentVoiceIndex, new: indexPath)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard self?.previewingVoiceIdentifier == voice.identifier else {
                return
            }
            
            GDATelemetry.track("settings.voice.preview", with: ["voice": voice.name])
            AppContext.process(TTSVoicePreviewEvent(name: voice.name) { [weak self] _ in
                guard self?.previewingVoiceIdentifier == voice.identifier else {
                    return
                }
                
                self?.previewingVoiceIdentifier = nil
                self?.refreshCells(previous: nil, new: indexPath)
                self?.updateVoiceOverFocus(on: indexPath)
            })
        }
        
        GDATelemetry.track("settings.voice.select", with: ["voice": voice.name])
        GDLogAppInfo("Selected voice: \(voice.name) (ID: \(voice.identifier))")
    }
    
    private func refreshCells(previous: IndexPath?, new: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            if let previous = previous {
                self?.tableView.reloadRows(at: [previous, new], with: .none)
            } else {
                self?.tableView.reloadRows(at: [new], with: .none)
            }
        }
    }
    
    private func updateVoiceOverFocus(on indexPath: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let updated = self?.tableView.cellForRow(at: indexPath) else {
                return
            }
            
            UIAccessibility.post(notification: .layoutChanged, argument: updated)
            GDLogAppVerbose("Updated VO focus on selected voice")
        }
    }
}

extension VoiceSettingsTableViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
