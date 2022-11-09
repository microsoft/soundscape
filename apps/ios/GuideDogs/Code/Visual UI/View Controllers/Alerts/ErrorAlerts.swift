//
//  ErrorAlerts.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

class ErrorAlerts {
    
    class func buildFitnessTrackingAlert(dismissHandler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("device_motion.enable.title"),
                                                message: GDLocalizedString("device_motion.enable.instructions"),
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        if let settingsAppUrl = URL(string: UIApplication.openSettingsURLString) {
            let openSettingsAction = UIAlertAction(title: GDLocalizedString("general.alert.open_settings"), style: .default, handler: { (_) in
                GDATelemetry.track("open_settings", with: ["context": "fitness_tracking_error"])
                UIApplication.shared.open(settingsAppUrl, options: [:], completionHandler: nil)
            })
            alertController.addAction(openSettingsAction)
            alertController.preferredAction = openSettingsAction
        }
        
        return alertController
    }
    
    class func buildLocationAlert(dismissHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        return ErrorAlerts.buildGeneric(title: GDLocalizedString("general.error.error_occurred"),
                                        message: GDLocalizedString("general.error.location_services_find_location_error.try_again"),
                                        dismissHandler: dismissHandler)
    }
    
    class func buildLocationServicesAlert(dismissHandler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("general.error.location_services_enable"),
                                                message: GDLocalizedString("general.error.location_services_enable_instructions.2"),
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        if let settingsAppUrl = URL(string: UIApplication.openSettingsURLString) {
            let openSettingsAction = UIAlertAction(title: GDLocalizedString("general.alert.open_settings"), style: .default, handler: { (_) in
                GDATelemetry.track("open_settings", with: ["context": "location_services_error"])
                UIApplication.shared.open(settingsAppUrl, options: [:], completionHandler: nil)
            })
            alertController.addAction(openSettingsAction)
            alertController.preferredAction = openSettingsAction
        }
        
        return alertController
    }
    
    class func buildGeneric(title: String, message: String?, dismissHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        return alertController
    }
    
    class func buildOfflineDefaultAlert(learnMoreHandler: ((UIAlertAction) -> Void)?, dismissHandler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("general.alert.offline_default.title"),
                                                message: GDLocalizedString("general.alert.offline_default.message"),
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        let learnMoreAction = UIAlertAction(title: GDLocalizedString("general.alert.offline.learn_more"), style: .default, handler: learnMoreHandler)
        alertController.addAction(learnMoreAction)
        alertController.preferredAction = learnMoreAction
        
        return alertController
    }
    
    class func buildOfflineSearchAlert(learnMoreHandler: ((UIAlertAction) -> Void)?, dismissHandler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("general.alert.offline_search.title"),
                                                message: GDLocalizedString("general.alert.offline_search.message"),
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        let learnMoreAction = UIAlertAction(title: GDLocalizedString("general.alert.offline.learn_more"), style: .default, handler: learnMoreHandler)
        alertController.addAction(learnMoreAction)
        alertController.preferredAction = learnMoreAction
        
        return alertController
    }
    
    class func buildOfflineHelpAlert(dismissHandler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("general.alert.offline_default.title"),
                                                message: GDLocalizedString("general.alert.offline_default.message"),
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"), style: .cancel, handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        return alertController
    }
    
    class func buildWiFiAlert(openSettingsHandler: ((UIAlertAction) -> Void)? = nil,
                              dismissHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("general.error.wifi"),
                                      message: GDLocalizedString("general.error.wifi.info"),
                                      preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"),
                                          style: .cancel,
                                          handler: dismissHandler)
        alertController.addAction(dismissAction)
        
        let openSettingsAction = UIAlertAction(title: GDLocalizedString("settings.screen_title"),
                                               style: .default) { (alertAction) in
                                                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                                    GDATelemetry.track("open_settings", with: ["context": "wifi_error"])
                                                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                                                }
                                                
                                                openSettingsHandler?(alertAction)
        }
        alertController.addAction(openSettingsAction)
        alertController.preferredAction = openSettingsAction

        return alertController
    }
    
    class func buildBLEAlert() -> UIAlertController {
        let alertController = UIAlertController(title: GDLocalizedString("general.error.ble.unauthorized.title"),
                                                message: GDLocalizedString("general.error.ble.unauthorized.message"),
                                                preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: GDLocalizedString("general.alert.dismiss"),
                                          style: .cancel)
        alertController.addAction(dismissAction)
        
        if let openSettingsURLString = URL(string: UIApplication.openSettingsURLString) {
            let openSettingsAction = UIAlertAction(title: GDLocalizedString("settings.screen_title"),
                                                   style: .default) { (_) in
                GDATelemetry.track("open_settings", with: ["context": "ble_error"])
                UIApplication.shared.open(openSettingsURLString, options: [:], completionHandler: nil)
            }
            
            alertController.addAction(openSettingsAction)
            alertController.preferredAction = openSettingsAction
        }
        
        return alertController
    }
    
}
