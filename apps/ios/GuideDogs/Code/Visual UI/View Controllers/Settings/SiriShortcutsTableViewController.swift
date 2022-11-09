//
//  SiriShortcutsTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import IntentsUI
import CocoaLumberjackSwift

class SiriShortcutsTableViewController: BaseTableViewController {
    
    // MARK: Properties
    
    private let appShortcuts: [INShortcut] = UserActionManager.appShortcuts
    private var voiceShortcuts: [INVoiceShortcut] = []
    
    /// Stores the app shortcuts and the voice shortcuts the user has added,
    /// which can include multiple voice shortcuts per app shortcut.
    /// `Any` can be `INShortcut` or `INVoiceShortcut`.
    private var displayShortcuts: [Any] = []
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = GDLocalizedString("siri_shortcuts.title.beta")
        
        reloadShortcuts()
        
        // If the user edited shortcuts in the Shortcuts app, reflect that here by reloading the data.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadShortcuts),
                                               name: Notification.Name.appWillEnterForeground,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.siri_shortcuts")
    }
    
    // MARK: Methods
    
    private func reloadDisplayShortcuts() {
        var displayShortcuts = [Any]()
        
        for appShortcut in appShortcuts {
            var voiceShortcuts = self.voiceShortcuts(for: appShortcut)
            if voiceShortcuts.isEmpty {
                displayShortcuts.append(appShortcut)
            } else {
                voiceShortcuts.sort {
                    // A shortcut without a custom invocation phrase should appear first (should be only one),
                    // then sort the others alphabetically.
                    if $0.invocationPhraseEqualToSuggested && !$1.invocationPhraseEqualToSuggested {
                        return true
                    } else if !$0.invocationPhraseEqualToSuggested && $1.invocationPhraseEqualToSuggested {
                        return false
                    } else {
                        return $0.invocationPhrase < $1.invocationPhrase
                    }
                }
                displayShortcuts.append(contentsOf: voiceShortcuts)
            }
        }
        
        self.displayShortcuts = displayShortcuts
    }
    
    private func reloadData() {
        self.reloadDisplayShortcuts()
        self.tableView.reloadData()
    }
    
    private func updateVoiceShortcuts(completion: (() -> Void)?) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcuts, error) in
            if let voiceShortcuts = voiceShortcuts {
                self.voiceShortcuts = voiceShortcuts
            } else if let error = error as NSError? {
                DDLogError("Error getting voice shortcuts: \(error.description)")
            }
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    @objc private func reloadShortcuts() {
        updateVoiceShortcuts {
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }
    
    // MARK: Helpers
    
    private func displayShortcut(at indexPath: IndexPath) -> Any {
        return displayShortcuts[indexPath.row]
    }
    
    private func appShortcut(for voiceShortcut: INVoiceShortcut) -> INShortcut? {
        guard let userActivity = voiceShortcut.shortcut.userActivity else {
            return nil
        }
        
        return appShortcuts.first(where: { $0.userActivity?.activityType == userActivity.activityType })
    }
    
    private func voiceShortcuts(for appShortcut: INShortcut) -> [INVoiceShortcut] {
        guard let userActivity = appShortcut.userActivity else {
            return []
        }
        
        return voiceShortcuts.filter { $0.shortcut.userActivity?.activityType == userActivity.activityType }
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return GDLocalizedString("siri_shortcuts.description")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayShortcuts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "siriShortcutCell", for: indexPath)
        
        cell.accessibilityTraits = [.button]
        cell.detailTextLabel?.accessibilityLabel = nil
        
        let displayShortcut = displayShortcut(at: indexPath)
        
        if let voiceShortcut = displayShortcut as? INVoiceShortcut {
            // We try to use the app shortcut title as it always shows the translated title
            if let appShortcut = appShortcut(for: voiceShortcut) {
                cell.textLabel?.text = appShortcut.userActivity?.title
            } else {
                cell.textLabel?.text = voiceShortcut.shortcut.userActivity?.title
            }
            
            if voiceShortcut.invocationPhraseEqualToSuggested {
                cell.detailTextLabel?.text = GDLocalizedString("general.alert.edit")
            } else {
                cell.detailTextLabel?.text = GDLocalizedString("general.text.string_with_quotation_marks", voiceShortcut.invocationPhrase)
            }
        } else if let appShortcut = displayShortcut as? INShortcut {
            cell.textLabel?.text = appShortcut.userActivity?.title
            
            if let image = UIImage(systemName: "plus") {
                cell.detailTextLabel?.attributedText = NSAttributedString(attachment: NSTextAttachment(image: image))
                cell.detailTextLabel?.accessibilityLabel = GDLocalizedString("general.alert.add")
            }
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displayShortcut = displayShortcut(at: indexPath)
        
        if let voiceShortcut = displayShortcut as? INVoiceShortcut {
            let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            
            present(viewController, animated: true, completion: nil)
        } else if let appShortcut = displayShortcut as? INShortcut {
            let viewController = INUIAddVoiceShortcutViewController(shortcut: appShortcut)
            viewController.modalPresentationStyle = .formSheet
            viewController.delegate = self
            
            present(viewController, animated: true, completion: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

// MARK: INUIAddVoiceShortcutViewControllerDelegate

extension SiriShortcutsTableViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if let error = error {
            self.dismiss(animated: true) {
                let alert = ErrorAlerts.buildGeneric(title: GDLocalizedString("general.error.error_occurred"),
                                                     message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            reloadShortcuts()
            self.dismiss(animated: true, completion: nil)
        }
        
        guard let userActivity = voiceShortcut?.shortcut.userActivity,
              let userAction = UserAction(userActivity: userActivity) else { return }
        
        GDATelemetry.track("user_activity.voice.added", value: userAction.rawValue)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: INUIEditVoiceShortcutViewControllerDelegate

extension SiriShortcutsTableViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        // In some cases, the shortcut does not update immediately, so we reload the shortcuts after dismissing the controller.
        // Repro: while editing the shortcut phrase, press the screen Done button (not the keyboard button).
        // This updates the shortcut, but only after the controller was dismissed.
        controller.dismiss(animated: true) { [weak self] in
            if let error = error {
                let alert = ErrorAlerts.buildGeneric(title: GDLocalizedString("general.error.error_occurred"),
                                                     message: error.localizedDescription)
                self?.present(alert, animated: true, completion: nil)
            } else {
                self?.reloadShortcuts()
            }
        }
        
        guard let userActivity = voiceShortcut?.shortcut.userActivity,
              let userAction = UserAction(userActivity: userActivity) else { return }
        
        GDATelemetry.track("user_activity.voice.updated", value: userAction.rawValue)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        if let voiceShortcut = voiceShortcuts.first(where: { $0.identifier == deletedVoiceShortcutIdentifier }),
           let userActivity = voiceShortcut.shortcut.userActivity,
           let userAction = UserAction(userActivity: userActivity) {
            GDATelemetry.track("user_activity.voice.deleted", value: userAction.rawValue)
        }
        
        controller.dismiss(animated: true) { [weak self] in
            // Shortcuts update only after the dismissal of the screen
            self?.reloadShortcuts()
        }
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true)
    }
    
}

// MARK: -

extension INVoiceShortcut {
    
    /// Returns `true` if the invocation phrase is equal to the suggested invocation phrase
    var invocationPhraseEqualToSuggested: Bool {
        guard let suggestedInvocationPhrase = shortcut.userActivity?.suggestedInvocationPhrase else { return false }
        return suggestedInvocationPhrase == invocationPhrase
    }
    
}
