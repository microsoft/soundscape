//
//  VersionHistoryTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class VersionHistoryTableViewController: BaseTableViewController {

    // MARK: - Properties

    private let features = NewFeatures.allFeaturesHistory()
    
    @IBOutlet weak var largeBannerContainerView: UIView!

    // MARK: View Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.about.whats_new")
    }
    
    // MARK: - Helper methods

    private func versions() -> [VersionString] {
        guard let versions = features?.keys.sorted(by: { $1 < $0 }) else { return [] }
        return versions
    }
    
    private func features(for section: Int) -> [FeatureInfo] {
        let versionKey = versions()[section]
        return features?[versionKey] ?? []
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return versions().count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return GDLocalizedString("settings.version.history.version", versions()[section].string)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return features(for: section).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "featureCell", for: indexPath)

        let feature = features(for: indexPath.section)[indexPath.row]
        
        cell.textLabel?.text = feature.localizedTitle
        cell.textLabel?.accessibilityLabel = feature.localizedTitle.accessibilityString()

        cell.detailTextLabel?.text = feature.localizedDescription
        cell.detailTextLabel?.accessibilityLabel = feature.localizedAccessibilityDescription.accessibilityString()

        return cell
    }
 
    // MARK: - Table view data delegate

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        
        view.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        view.textLabel?.textColor = UIColor.white
        view.backgroundView?.backgroundColor = self.view.backgroundColor
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = NewFeaturesViewController(nibName: "NewFeaturesView", bundle: nil)

        vc.features = [features(for: indexPath.section)[indexPath.row]]
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.accessibilityViewIsModal = true

        self.present(vc, animated: !UIAccessibility.isVoiceOverRunning, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension VersionHistoryTableViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerView.setHeight(height)
        tableView.reloadData()
    }
    
}
