//
//  LocationPermissionViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreLocation

class LocationPermissionViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var buttonLabel: UILabel!
    
    var displayAsModal: Bool = false
    
    private var geolocationManager: GeolocationManager {
        return AppContext.shared.geolocationManager
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("location_permission")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        configureView()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: headerLabel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func dismissView() {
        if displayAsModal {
            // Unwind to Home
            self.performSegue(withIdentifier: "UnwindToHomeSegue", sender: nil)
        } else {
            // Regardless of whether the user accepted or rejected the permission, continue to
            // the next screen.
            self.performSegue(withIdentifier: "completeLocation", sender: nil)
        }
    }
    
    private func configureView() {
        // Only if the authorization status is `notDetermined` we are able to request authorization from iOS (user pop-up).
        // In any other case we should open the app settings in the iOS Settings app.
        
        switch geolocationManager.coreLocationAuthorizationStatus {
        case .notDetermined, .fullAccuracyLocationAuthorized:
            descriptionLabel.text = GDLocalizedString("first_launch.location.text")
            buttonLabel.text = GDLocalizedString("first_launch.location.enable_location")
        case .reducedAccuracyLocationAuthorized:
            descriptionLabel.text = GDLocalizedString("general.error.precise_location") + "\n\n" + GDLocalizedString("general.error.location_services.precise_location.instructions")
            buttonLabel.text = GDLocalizedString("general.alert.open_settings")
        default:
            descriptionLabel.text = GDLocalizedString("general.error.location_services_enable_instructions.3")
            buttonLabel.text = GDLocalizedString("general.alert.open_settings")
        }
    }
    
    @IBAction func onEnableButtonTouchUp(_ sender: UIButton) {
        guard geolocationManager.coreLocationServicesEnabled else {
            let alert = ErrorAlerts.buildLocationServicesAlert(dismissHandler: nil)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Only if the authorization status is `notDetermined` we are able to request authorization from iOS (user pop-up).
        // In any other case we should open the app settings in the iOS Settings app.
        
        switch geolocationManager.coreLocationAuthorizationStatus {
        case .notDetermined:
            geolocationManager.requestCoreLocationAuthorization()
        case .fullAccuracyLocationAuthorized:
            dismissView()
        default:
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                GDATelemetry.track("open_settings", with: ["context": "authorize_location_services_first_launch"])
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
    }
    
    @objc func applicationDidBecomeActive() {
        guard geolocationManager.coreLocationServicesEnabled else {
            let alert = ErrorAlerts.buildLocationServicesAlert(dismissHandler: nil)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        switch geolocationManager.coreLocationAuthorizationStatus {
        case .fullAccuracyLocationAuthorized:
            dismissView()
        default:
            configureView()
        }
    }
    
}
