//
//  EnableLocationServicesViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreLocation

class EnableLocationServicesViewController: UIViewController {
    
    @IBOutlet weak var enableButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("enable_location_services")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func onEnableButtonTouchUp(_ sender: UIButton) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            GDATelemetry.track("open_settings", with: ["context": "enable_location_services"])
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    @objc func applicationDidBecomeActive() {
        // If a user turned on location services, dismiss this screen
        if AppContext.shared.geolocationManager.coreLocationServicesEnabled {
            navigationController?.popViewController(animated: true)
        }
    }
    
}
