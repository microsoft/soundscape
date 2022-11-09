//
//  AboutViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import SafariServices
import CocoaLumberjackSwift

class AboutHeaderCell: UITableViewCell {
    @IBOutlet weak var versionLabel: UILabel!
}

class AboutApplicationViewController: BaseTableViewController {
    
    // MARK: Cell Content
    private struct AboutLinkCellModel {
        let localizedTitle: String
        
        let segue: String?
        let url: URL?
        
        let telemetryEventName: String?
        
        init(localizedTitle: String, url: URL, event: String? = nil) {
            self.localizedTitle = localizedTitle
            self.url = url
            self.segue = nil
            self.telemetryEventName = event
        }
        
        init(localizedTitle: String, segue: String, event: String? = nil) {
            self.localizedTitle = localizedTitle
            self.url = nil
            self.segue = segue
            self.telemetryEventName = event
        }
    }
    
    // MARK: Properties
    
    private let sectionCount = 1
    
    private let headerPath = IndexPath(row: 0, section: 0)
    
    private var aboutLinks: [AboutLinkCellModel] {
        var links = [
            AboutLinkCellModel(localizedTitle: GDLocalizedString("settings.about.title.whats_new"), segue: "ShowVersionHistorySegue"),
            AboutLinkCellModel(localizedTitle: GDLocalizationUnnecessary("LINK TO YOUR PRIVACY POLICY"), url: AppContext.Links.privacyPolicyURL(for: LocalizationContext.currentAppLocale), event: "about.privacy_policy"),
            AboutLinkCellModel(localizedTitle: GDLocalizationUnnecessary("LINK TO YOUR SERVICES AGREEMENT"), url: AppContext.Links.servicesAgreementURL(for: LocalizationContext.currentAppLocale), event: "about.services_agreement"),
            AboutLinkCellModel(localizedTitle: GDLocalizedString("settings.about.title.third_party"), segue: "ShowThirdPartyNoticesSegue")
        ]
        
        if LocalizationContext.currentAppLocale == Locale.frFr {
            // If the app is localized in fr-FR, include a link to the France Accessibility landing page
            links.append(AboutLinkCellModel(localizedTitle: GDLocalizationUnnecessary("Accessibilité: partiellement conforme"), url: AppContext.Links.accessibilityFrance, event: "about.accessibility_fr_fr"))
        }
        
        return links
    }
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: .zero) // Removes the footer separators
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.about")
    }
    
    // MARK: UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionCount
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return aboutLinks.count + 1
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Handle the header cell separately
        if indexPath == headerPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AboutHeaderCellPrototype", for: indexPath) as! AboutHeaderCell
            cell.versionLabel.text = GDLocalizedString("settings.version.about.version", AppContext.appVersion, AppContext.appBuild)
            return cell
        }
        
        // Make sure the index path is valid, otherwise return a default cell
        guard indexPath.section < sectionCount, indexPath.row - 1 < aboutLinks.count, indexPath.row > 0 else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AboutLinkCellPrototype", for: indexPath)
            return cell
        }
        
        // Set the title for the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "AboutLinkCellPrototype", for: indexPath)
        cell.textLabel?.text = aboutLinks[indexPath.row - 1].localizedTitle
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        // Make sure the index path is valid, otherwise return a default cell
        guard indexPath.section < sectionCount, indexPath.row - 1 < aboutLinks.count, indexPath.row > 0 else {
            return
        }
        
        let model = aboutLinks[indexPath.row - 1]
        
        if let eventName = model.telemetryEventName {
            GDATelemetry.trackScreenView(eventName)
        }
        
        // If the cell has a segue, perform it
        if let segue = model.segue {
            performSegue(withIdentifier: segue, sender: self)
            return
        }
        
        // Otherwise, if the cell has a URL, load it
        if let url = model.url {
            openURL(url: url)
        }

    }
    
    // MARK: Actions
    
    private func openURL(url: URL) {
        DDLogInfo("Opening URL: \(url)")
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredBarTintColor = Colors.Background.primary
        safariVC.preferredControlTintColor = Colors.Foreground.primary
        
        present(safariVC, animated: true, completion: nil)
    }
    
}

extension AboutApplicationViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
