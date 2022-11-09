//
//  MotionPermissionViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreMotion

class MotionPermissionViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var buttonLabel: UILabel!
    
    var displayAsModal = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("motion_permission")
        
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
    
    private func configureView() {
        // Only if the authorization status is `notDetermined` we are able to request authorization from iOS (user pop-up).
        // In any other case we should open the app settings in the iOS Settings app.
        
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined, .authorized:
            descriptionLabel.text = GDLocalizedString("first_launch.device_motion.text")
            buttonLabel.text = GDLocalizedString("device_motion.authorize.title")
        case .restricted: // Motion tracking disabled
            descriptionLabel.text = GDLocalizedString("device_motion.enable.description") + "\n\n" + GDLocalizedString("device_motion.enable.instructions")
            buttonLabel.text = GDLocalizedString("general.alert.open_settings")
        default:
            descriptionLabel.text = GDLocalizedString("device_motion.authorize.description") + "\n\n" + GDLocalizedString("device_motion.authorize.instructions")
            buttonLabel.text = GDLocalizedString("general.alert.open_settings")
        }
    }
    
    @IBAction func onEnableButtonTouchUp(_ sender: UIButton) {
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            showNextScreen()
        case .notDetermined:
            MotionActivityContext.requestAuthorization { (_, error) in
                let statusLabel: String
                if let error = error as NSError?, !UIDeviceManager.isSimulator {
                    switch error.code {
                    case Int(CMErrorMotionActivityNotAvailable.rawValue):
                        statusLabel = "not_available"
                    case Int(CMErrorMotionActivityNotAuthorized.rawValue):
                        statusLabel = "not_authorized"
                    case Int(CMErrorMotionActivityNotEntitled.rawValue):
                        statusLabel = "not_entitled"
                    default:
                        statusLabel = "error_code_\(error.code)"
                    }
                } else {
                    statusLabel = "authorized"
                }
                
                GDATelemetry.track("motion_permission_request", with: ["status": statusLabel])
            }
        default:
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                GDATelemetry.track("open_settings", with: ["context": "authorize_motion_services_first_launch"])
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func showNextScreen() {
        if displayAsModal {
            performSegue(withIdentifier: "UnwindToHomeSegue", sender: nil)
        } else {
            FirstUseExperience.setDidComplete(for: .oobe)
            performSegue(withIdentifier: "finishInitializationSegue", sender: nil)
        }
    }
    
    @objc func applicationDidBecomeActive() {
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            showNextScreen()
        default:
            configureView()
        }
    }
    
}
