//
//  AuthorizeLocationsViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreLocation

class AuthorizeLocationsViewController: UIViewController {
    
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    private var geolocationManager: GeolocationManager {
        return AppContext.shared.geolocationManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureView()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func configureView() {
        switch geolocationManager.coreLocationAuthorizationStatus {
        case .reducedAccuracyLocationAuthorized:
            instructionsLabel.text = GDLocalizedString("general.error.location_services.precise_location.instructions")
        default:
            instructionsLabel.text = GDLocalizedString("general.error.location_services.authorize.instructions")
        }
    }
    
    @IBAction func onEnableButtonTouchUp(_ sender: UIButton) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            GDATelemetry.track("open_settings", with: ["context": "authorize_location_services"])
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    @objc func applicationDidBecomeActive() {
        // If the user fully authorized location services, dismiss this screen
        switch geolocationManager.coreLocationAuthorizationStatus {
        case .fullAccuracyLocationAuthorized:
            self.performSegue(withIdentifier: "unwindFromAuthorize", sender: nil)
        default:
            configureView()
        }
    }
    
}
