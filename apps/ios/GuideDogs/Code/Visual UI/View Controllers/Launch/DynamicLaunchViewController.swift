//
//  DynamicLaunchViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import Combine

class DynamicLaunchViewController: UIViewController {

    private var validator: TTSVoiceValidator?
    private var cancellable: AnyCancellable?
    
    /// Called after the view controller's view is loaded into memory.
    ///
    /// This method should be used for initializing any app components that need
    /// static initialization or are global.
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        LoggingContext.shared.start()
        
        GDLogAppInfo("Device info: \(UIDevice.current.modelName), iOS \(UIDevice.current.systemVersion), v\(AppContext.appVersion) (\(AppContext.appBuild)), \(LocalizationContext.currentAppLocale.identifierHyphened)")
        
        // Remove user defaults if we are in a test environment
        let testEnvironment = (BuildSettings.isTesting)
        
        if testEnvironment, let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        
        // If we aren't in the test environment, register search providers for SpatialDataSearch
        if !testEnvironment {
            SpatialDataCache.useDefaultSearchProviders()
            SpatialDataCache.useDefaultGeocoder()
        }
        
        if !testEnvironment, !UIDeviceManager.isSimulator {
            AppCenter.start(withAppSecret: "<#Secret#>", services: [Analytics.self, Crashes.self])
            Analytics.enabled = !SettingsContext.shared.telemetryOptout
            Crashes.enabled = !SettingsContext.shared.telemetryOptout
        }
    }
    
    /// Notifies the view controller that its view was added to a view hierarchy.
    ///
    /// This method should be used for initializing any app components that are
    /// non-static or not already initialized. It should also be used for starting
    /// app components which need to be explicitly started.
    ///
    /// - Parameter animated: If `true`, the view was added to the window using an animation.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Always turn callouts on when the app starts
        SettingsContext.shared.automaticCalloutsEnabled = true
        
        // Force the instantiation of AppContext now by accessing AppContext.shared
        _ = AppContext.shared
        
        // Instantie the telemetry helper with the appContext object
        GDATelemetry.helper = TelemetryHelper(appContext: AppContext.shared)
        
        // Do some logging since the app has launched
        if let helper = GDATelemetry.helper {
            GDATelemetry.track("device_snapshot", with: helper.deviceSnapshot)
            GDATelemetry.track("app_snapshot", with: helper.appSnapshot)
            GDATelemetry.track("ios_accessibility", with: helper.accessibilityFeatures)
        }
        
        guard let id = SettingsContext.shared.voiceId else {
            completeInitialization()
            return
        }
        
        validator = TTSVoiceValidator(identifier: id)
        cancellable = validator?.validate().sink { isValid in
            if !isValid {
                // If the previously selected voice isn't valid anymore, reset it
                SettingsContext.shared.voiceId = nil
                GDLogAudioVerbose("TTS voice no longer available (\(id)). Reverting to default.")
            } else {
                GDLogAudioVerbose("TTS voice validated!")
            }
            
            self.validator = nil
            self.cancellable = nil
            self.completeInitialization()
        }
    }
    
    private func completeInitialization() {
        // Initialize the experiment manager before displaying the initial view
        AppContext.shared.experimentManager.delegate = self
        AppContext.shared.experimentManager.initialize()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension DynamicLaunchViewController: ExperimentManagerDelegate {
    func onExperimentManagerReady() {
        // Log experiment state
        if let helper = GDATelemetry.helper {
            GDATelemetry.track("experiment_snapshot", with: helper.experimentSnapshot)
        }
        
        DispatchQueue.main.async {
            AppContext.shared.experimentManager.delegate = nil
            
            self.configureInitialAppView()
        }
    }
    
    private func configureInitialAppView() {
        // Configure the appropriate view for the app
        if FirstUseExperience.didComplete(.oobe) {
            AppContext.shared.start()
            
            LaunchHelper.configureAppView(with: .main)
        } else {
            // Since this is a first launch, set the app version for the new features feature to the current version
            SettingsContext.shared.newFeaturesLastDisplayedVersion = AppContext.appVersion
            
            // App hasn't gone through the first time initialization yet, so start it. This
            // will run both the permissions request screens and the First Launch screens
            LaunchHelper.configureAppView(with: .firstLaunch)
        }
    }
}
