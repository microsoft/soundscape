//
//  AuthorizeMotionFitnessViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreMotion

class AuthorizeMotionFitnessViewController: UIViewController {
    
    @IBOutlet weak var enableButton: UIButton!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("authorize_motion_fitness_services")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: Actions
    
    @IBAction func onEnableButtonTouchUp(_ sender: UIButton) {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            GDATelemetry.track("open_settings", with: ["context": "authorize_fitness_tracking"])
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: Notifications
    
    @objc func applicationDidBecomeActive() {
        // If a user turned on Motion & Fitness, dismiss this screen
        MotionActivityContext.requestAuthorization { (authorized, _) in
            if authorized {
                self.performSegue(withIdentifier: "unwindFromAuthorizeMotionFitness", sender: nil)
            }
        }
    }
}
