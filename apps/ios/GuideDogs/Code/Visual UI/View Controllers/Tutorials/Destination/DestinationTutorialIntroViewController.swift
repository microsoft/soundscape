//
//  DestinationTutorialViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import AVFoundation
import CoreLocation

class DestinationTutorialIntroViewController: DestinationTutorialPage {
    
    // MARK: Content Strings
    
    let introPart1 = GDLocalizedString("tutorial.beacons.text.IntroPart1")
    let introPart2 = GDLocalizedString("tutorial.beacons.text.IntroPart2")
    
    /// Reference to the original view controller that launched the demo (e.g. home or help)
    weak var source: UIViewController?
    
    /// Used for telemetry to identify the context (source) of the viewing this screen
    var logContext: String?

    /// The key for the ReferenceEntity the user selected from the Nearby Places List
    var entityKey: String?
    
    var player: FadeableAudioPlayer?
    var backgroundVolume: Float = 0.1
    var fadeInDuration: TimeInterval = 1.5

    @IBOutlet weak var exitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem.defaultBackBarButtonItem
        
        delegate = self
        
        exitButton.setTitle(GDLocalizedString("tutorial.skip"), for: .normal)
        
        GDATelemetry.trackScreenView("tutorial.beacons", with: logContext == nil ? nil : ["context": logContext!])
            
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AppContext.shared.audioEngine.session)
    }
    
    @objc func handleAudioSessionInterruption(_ notification: NSNotification) {
        exitTutorial()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppContext.shared.isInTutorialMode = true
        
        // Clear destination if needed
        try? AppContext.shared.spatialDataContext.destinationManager.clearDestination(logContext: "tutorial.beacon.start_tutorial")

        navigationController?.setNavigationBarHidden(true, animated: true)
        
        guard let player = FadeableAudioPlayer.fadeablePlayer(with: "tutorial_background_music", fileTypeHint: AVFileType.mp3.rawValue) else {
            GDLogAppError("Destination tutorial error: file not found.")
            return
        }
        
        player.numberOfLoops = -1 // play indefinitely
        self.player = player
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)

        pauseBackgroundTrack(nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let vc = segue.destination as? SearchTableViewController {
            vc.delegate = self
            
            GDATelemetry.track("tutorial.beacon.set_beacon")
        }
        
        if let vc = segue.destination as? DestinationTutorialViewController {
            vc.source = source
            vc.entityKey = entityKey
        }
    }
    
    @IBAction func exitTutorial() {
        GDATelemetry.track("tutorial.beacon.exit")
        if GDATelemetry.helper?.tutorialBeaconStatus != "finished" {
            GDATelemetry.helper?.tutorialBeaconStatus = "exited"
        }
        
        tutorialComplete()
    }
}

extension DestinationTutorialIntroViewController: DestinationTutorialPageDelegate {
    func getEntityKey() -> String? {
        return entityKey
    }
    
    func pauseBackgroundTrack(_ completion: (() -> Void)?) {
        player?.fadeOut(completion)
    }
    
    func resumeBackgroundTrack() {
        player?.fadeIn(to: backgroundVolume, duration: fadeInDuration)
    }
    
    func pageComplete() {
        performSegue(withIdentifier: "ContinueDestinationDemoSegue", sender: nil)
    }
    
    func tutorialComplete() {
        if self.navigationController?.presentingViewController != nil {
            FirstUseExperience.setDidComplete(for: .beaconTutorial)
            self.dismiss(animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "ExitTutorialSegue", sender: self)
        }
        
        AppContext.shared.isInTutorialMode = false
    }
}

extension DestinationTutorialIntroViewController: POITableViewDelegate {
    var poiAccessibilityHint: String {
        return GDLocalizedString("tutorial.beacon.mark_location.acc_hint")
    }
    
    var allowCurrentLocation: Bool {
        return false
    }
    
    var allowMarkers: Bool {
        return false
    }
    
    var usageLog: String {
        return "tutorial.beacon"
    }
    
    var doneNavigationItem: Bool {
        return false
    }
    
    func didSelect(poi: POI) {
        do {
            entityKey = try AppContext.shared.spatialDataContext.destinationManager.setDestination(entityKey: poi.key, enableAudio: false, userLocation: AppContext.shared.geolocationManager.location, estimatedAddress: nil, logContext: "tutorial.beacon")
        } catch {
            GDLogAppError("Unable to set destination in Destination tutorial")
        }
        
        pageComplete()
    }
    
    func didSelect(currentLocation location: CLLocation) {
        fatalError("The current location option should be disabled for this view controller!")
    }
    
    var isCachingRequired: Bool {
        // The ability to cache a location (e.g., unencumbered coordinate is available) is
        // not required for setting an audio beacon
        return false
    }
}
