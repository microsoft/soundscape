//
//  LanguageTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class LanguageTableViewController: UITableViewController {
    
    private struct Section {
        static let units = 0
        static let language = 1
    }
    
    // MARK: - Properties
    
    private let locales = LocalizationContext.supportedLocales
    private var selectedLocale = LocalizationContext.currentAppLocale

    @IBOutlet weak var largeBannerContainerView: UIView!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCell(UnitsOfMeasureTableViewCell.self)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.language")
    }
    
    // MARK: Changing Locale
    
    private func tryChangingLocale(_ locale: Locale) {
        guard locale != LocalizationContext.currentAppLocale else {
            return
        }
        
        selectedLocale = locale

        // Change locale
        LocalizationContext.currentAppLocale = locale
        
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        
        GDATelemetry.track("settings.language.first_launch.user_change", with: ["locale": locale.identifier])
        
        // Reloads the entire view stack to update the language
        LaunchHelper.configureAppView(with: .main)
    }
    
    private func confirmLocaleChange(_ locale: Locale, completionHandler: @escaping (Bool) -> Void) {
        let localeLanguageName = locale.localizedDescription(with: LocalizationContext.currentAppLocale)
        
        let alert = UIAlertController(title: GDLocalizedString("settings.language.change_alert", localeLanguageName),
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel) { (_) in
            completionHandler(false)
        })
        
        let changeAction = UIAlertAction(title: GDLocalizedString("settings.language.change_alert_action", localeLanguageName), style: .default) { (_) in
            completionHandler(true)
        }
        alert.addAction(changeAction)
        alert.preferredAction = changeAction
        
        present(alert, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.units: return GDLocalizedString("settings.section.units")
        case Section.language: return GDLocalizedString("settings.language.screen_title")
        default: return nil
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.units: return 1
        case Section.language: return locales.count
        default: return 0
        }
    }
    
    override  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        
        view.textLabel?.textColor = Colors.Foreground.primary
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == Section.language else {
            let cell: UnitsOfMeasureTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "languageCell", for: indexPath)
        
        let locale = locales[indexPath.row]
        
        // Show the language in it's original locale
        let title = locale.localizedDescription
        cell.textLabel?.text = title
        cell.textLabel?.accessibilityLanguage = locale.languageCode!
        cell.textLabel?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        // Show the language with the current locale
        let subtitle = locale.localizedDescription(with: LocalizationContext.currentAppLocale)
        cell.detailTextLabel?.text = title == subtitle ? nil : subtitle
        cell.detailTextLabel?.textColor = #colorLiteral(red: 0.7192531228, green: 0.9648788571, blue: 0.969180882, alpha: 1)
        
        cell.accessibilityTraits = [.button]
        
        if locale.identifierHyphened == selectedLocale.identifierHyphened {
            cell.accessoryType = .checkmark
            cell.selectionStyle = .none
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    // MARK: - Table view data delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Section.language else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let locale = locales[indexPath.row]
        
        confirmLocaleChange(locale) { [weak self] (confirmed) in
            guard confirmed else {
                return
            }
            
            self?.tryChangingLocale(locale)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension LanguageTableViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
