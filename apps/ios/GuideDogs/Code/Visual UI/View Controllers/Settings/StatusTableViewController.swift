//
//  StatusTableViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CocoaLumberjackSwift

class StatusTableViewController: BaseTableViewController {

    private struct Section {
        static let gps = 0
        static let audio = 1
        static let cache = 2
    }
    
    private struct CellIdentifier {
        static let gps = "GPSStatus"
    }
    
    private struct Segue {
        static let showLoadingModal = "ShowLoadingModalSegue"
    }
    
    var reenableCalloutsAfterReload = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.registerCell(ButtonTableViewCell.self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLocationUpdated(notification:)),
                                               name: Notification.Name.locationUpdated,
                                               object: AppContext.shared.spatialDataContext)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("settings.troubleshooting")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.spatialDataStateChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.locationUpdated, object: AppContext.shared.spatialDataContext)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LoadingModalViewController {
            vc.loadingMessage = GDLocalizedString("text.cleaning_things")
            
            NotificationCenter.default.addObserver(self, selector: #selector(spatialDataStateChanged(_:)), name: Notification.Name.spatialDataStateChanged, object: nil)
        }
    }
    
    @objc
    private func onLocationUpdated(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [IndexPath(row: 0, section: Section.gps)], with: .none)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.gps:     return 1
        case Section.audio:   return 1
        case Section.cache:   return 1
        default:              return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.gps:     return GDLocalizedString("troubleshooting.gps_status")
        case Section.audio:   return GDLocalizedString("troubleshooting.check_audio")
        case Section.cache:   return GDLocalizedString("troubleshooting.cache")
        default:              return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case Section.gps:
            if SettingsContext.shared.metricUnits {
                return GDLocalizedString("troubleshooting.gps_status.explanation.meters")
            } else {
                return GDLocalizedString("troubleshooting.gps_status.explanation.feet")
            }
        case Section.audio: return GDLocalizedString("troubleshooting.check_audio.explanation")
        case Section.cache: return GDLocalizedString("troubleshooting.cache.explanation")
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.gps:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.gps, for: indexPath)
            
            guard let accuracy = AppContext.shared.geolocationManager.location?.horizontalAccuracy else {
                return cell
            }
            
            if SettingsContext.shared.metricUnits {
                cell.textLabel?.text = GDLocalizedString("troubleshooting.gps_status.meters", String(Int(accuracy)))
            } else {
                let feet = Measurement(value: accuracy, unit: UnitLength.meters).converted(to: UnitLength.feet).value
                cell.textLabel?.text = GDLocalizedString("troubleshooting.gps_status.feet", String(Int(feet)))
            }
            
            return cell
            
        case Section.audio:
            let cell: ButtonTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            
            cell.backgroundColor = Colors.Background.quaternary
            cell.button.removeTarget(self, action: #selector(clearCacheTouchUpInside), for: .touchUpInside)
            cell.button.addTarget(self, action: #selector(crosscheckTouchUpInside), for: .touchUpInside)
            cell.button.accessibilityLabel = GDLocalizedString("troubleshooting.check_audio")
            cell.button.accessibilityHint = GDLocalizedString("troubleshooting.check_audio.hint")
            cell.button.backgroundColor = Colors.Background.primary
            cell.label.text = GDLocalizedString("troubleshooting.check_audio")
            
            return cell
            
        case Section.cache:
            let cell: ButtonTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            
            cell.backgroundColor = Colors.Background.quaternary
            cell.button.removeTarget(self, action: #selector(crosscheckTouchUpInside), for: .touchUpInside)
            cell.button.addTarget(self, action: #selector(clearCacheTouchUpInside), for: .touchUpInside)
            cell.button.accessibilityLabel = GDLocalizedString("settings.clear_data")
            cell.button.accessibilityHint = GDLocalizedString("troubleshooting.cache.hint")
            cell.button.backgroundColor = Colors.Background.error
            cell.label.text = GDLocalizedString("settings.clear_data")
            
            return cell
            
        default:
            fatalError()
        }
        
    }

}

extension StatusTableViewController {
    
    @objc func crosscheckTouchUpInside() {
        GDLogAppInfo("Play crosscheck audio")
        AppContext.process(CheckAudioEvent())
    }
    
    @objc func clearCacheTouchUpInside() {
        // Only allow the cache to be deleted if we have a network connection to reload the cache
        guard AppContext.shared.offlineContext.state != .offline else {
            let alert = UIAlertController(title: GDLocalizedString("general.error.network_connection_required"),
                                          message: GDLocalizedString("general.error.network_connection_required.deleting_data"),
                                          preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        let alert = UIAlertController(title: GDLocalizedString("settings.clear_cache.alert_title"),
                                      message: GDLocalizedString("settings.clear_cache.alert_message"),
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.delete"), style: .destructive, handler: { _ in
            AppContext.shared.eventProcessor.hush(playSound: false)
            
            if SettingsContext.shared.automaticCalloutsEnabled {
                self.reenableCalloutsAfterReload = true
                SettingsContext.shared.automaticCalloutsEnabled = false
            }
            
            self.displayMarkersPrompt()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func displayMarkersPrompt() {
        let alert = UIAlertController(title: GDLocalizedString("settings.clear_cache.markers.alert_title"),
                                      message: GDLocalizedString("settings.clear_cache.markers.alert_message"),
                                      preferredStyle: UIAlertController.Style.actionSheet)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: { [weak self] _ in
            if self?.reenableCalloutsAfterReload ?? false {
                SettingsContext.shared.automaticCalloutsEnabled = true
            }
        }))
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.keep"), style: .default, handler: { _ in
            self.performSegue(withIdentifier: Segue.showLoadingModal, sender: self)
            
            // Check that tiles can be downloaded before we attempt to delete the cache
            AppContext.shared.spatialDataContext.checkServiceConnection { [weak self] (success) in
                guard success else {
                    self?.displayUnableToClearCacheWarning()
                    return
                }
                
                // Clear the cache and keep the markers
                self?.clearCache(false)
            }
        }))
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.delete"), style: .destructive, handler: { _ in
            self.performSegue(withIdentifier: Segue.showLoadingModal, sender: self)
            
            // Check that tiles can be downloaded before we attempt to delete the cache
            AppContext.shared.spatialDataContext.checkServiceConnection { [weak self] (success) in
                guard success else {
                    self?.displayUnableToClearCacheWarning()
                    return
                }
                
                // Clear the cache and delete the markers
                self?.clearCache(true)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func clearCache(_ deletePORs: Bool) {
        guard let database = try? RealmHelper.getDatabaseRealm() else {
            DDLogError("Error attempting to get database data!")
            return
        }
        
        var storedAddresses: [Address] = []
        
        if deletePORs {
            do {
                // Remove the reference entities (regardless of type)
                try ReferenceEntity.removeAll()
                
                // Remove all routes
                try Route.deleteAll()
            } catch {
                GDLogAppError("Failed to remove all Reference Entities!")
            }
        } else {
            // Preserve addresses since they can't be reloaded like POI reference points can
            for por in database.objects(ReferenceEntity.self) {
                if let entity = por.getPOI() as? Address, storedAddresses.contains(where: { $0.key == entity.key }) == false {
                    // Copy the address
                    storedAddresses.append(Address(value: entity))
                }
            }
        }
        
        let success = AppContext.shared.spatialDataContext.clearCache()
        
        GDATelemetry.track("settings.clear_cache", with: ["keep_user_data": String(!deletePORs)])
        
        guard success else {
            GDLogSpatialDataError("Error attempting to delete cached data!")
            return
        }
        
        guard storedAddresses.count > 0 else {
            GDLogSpatialDataWarn("Cached data deleted")
            return
        }
        
        // Save stored addresses
        guard let cache = try? RealmHelper.getCacheRealm() else {
            GDLogSpatialDataError("Cached data deleted, but couldn't get cache realm to restore addresses!")
            return
        }
        
        do {
            try cache.write {
                for address in storedAddresses {
                    cache.create(Address.self, value: address, update: .modified)
                }
            }
        } catch {
            GDLogSpatialDataError("Cached data deleted, but couldn't restore addresses!")
            return
        }
        
        GDLogSpatialDataWarn("Cached data deleted and addresses restored")
    }
    
    private func displayUnableToClearCacheWarning() {
        // Dismiss the loading screen
        dismiss(animated: true) { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let alert = UIAlertController(title: GDLocalizedString("settings.clear_cache.no_service.title"),
                                          message: GDLocalizedString("settings.clear_cache.no_service.message"),
                                          preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                
                NotificationCenter.default.removeObserver(self, name: Notification.Name.spatialDataStateChanged, object: nil)
                
                if self.reenableCalloutsAfterReload {
                    SettingsContext.shared.automaticCalloutsEnabled = true
                }
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func spatialDataStateChanged(_ notification: Notification) {
        guard let state = notification.userInfo?[SpatialDataContext.Keys.state] as? SpatialDataState else {
            return
        }
        
        guard state == .ready || state == .error else {
            return
        }
        
        NotificationCenter.default.removeObserver(self)
        
        if reenableCalloutsAfterReload {
            SettingsContext.shared.automaticCalloutsEnabled = true
        }
        
        do {
            try ReferenceEntity.cleanCorruptEntities()
            GDLogAppVerbose("Successfully removed any corrupted Reference Entity objects (if any existed)")
        } catch {
            GDLogAppError("Unable to remove corrupted Reference Entity objects")
        }
        
        dismiss(animated: true, completion: nil)
    }
}
