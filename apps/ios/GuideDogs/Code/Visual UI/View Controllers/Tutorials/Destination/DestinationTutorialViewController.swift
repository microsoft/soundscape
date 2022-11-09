//
//  DestinationTutorialViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import AVFoundation

class DestinationTutorialViewController: CustomPageViewController, AVAudioPlayerDelegate {
    
    @IBOutlet weak var exitButton: UIButton!
    
    private var presentedAlertController: UIAlertController?
    var player: FadeableAudioPlayer?
    var backgroundVolume: Float = 0.1
    var fadeInDuration: TimeInterval = 1.5
    
    var entityKey: String?
    
    /// Reference to the original view controller that launched the demo (e.g. home or help)
    weak var source: UIViewController?
    
    override func loadSteps() {
        steps = ["beacon", "home", "callouts"].map({ (page) -> UIViewController in
            return self.loadPage("DestinationTutorial", "\(page)DTViewController")
        })
        
        for step in steps ?? [] {
            if let page = step as? DestinationTutorialPage {
                page.delegate = self
                page.pageFinished = false
            }
        }
    }
    
    override func viewDidLoad() {
        delegate = self
        
        // This must be set before calling super.viewDidLoad() in order to disable gestures
        allowsGestures = false
        
        super.viewDidLoad()
        
        guard let player = FadeableAudioPlayer.fadeablePlayer(with: "tutorial_background_music", fileTypeHint: AVFileType.mp3.rawValue) else {
            GDLogAppError("Destination tutorial error: file not found.")
            return
        }
        
        exitButton.setTitle(GDLocalizedString("tutorial.skip"), for: .normal)
        
        player.numberOfLoops = -1 // play indefinitely
        player.delegate = self
        self.player = player
        
        NotificationCenter.default.post(name: NSNotification.Name.disableMagicTap, object: self)
        NotificationCenter.default.post(name: NSNotification.Name.disableDestinationGeofence, object: self)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AppContext.shared.audioEngine.session)
    }
    
    @objc func handleAudioSessionInterruption(_ notification: NSNotification) {
        tutorialComplete()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pageControl.isHidden = true
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        player?.fadeIn(to: backgroundVolume, duration: fadeInDuration)
        
        if SettingsContext.shared.automaticCalloutsEnabled {
            // Toggle callouts off for now
            AppContext.process(ToggleAutoCalloutsEvent(playSound: false))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        player?.fadeOut { [weak self] in
            self?.player = nil
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.enableMagicTap, object: self)
        NotificationCenter.default.post(name: NSNotification.Name.enableDestinationGeofence, object: self)
        
        AppContext.shared.eventProcessor.hush(playSound: false)
        
        if !SettingsContext.shared.automaticCalloutsEnabled {
            // Toggle callouts back on
            AppContext.process(ToggleAutoCalloutsEvent(playSound: false))
        }
        
        guard !AppContext.shared.spatialDataContext.destinationManager.isDestinationSet else {
            // Remove destination by clearing from cache
            try? AppContext.shared.spatialDataContext.destinationManager.clearDestination(logContext: "tutorial.beacon.clear_test_beacon")
            return
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // Remove reference to `presentedAlertController`
        presentedAlertController = nil
        
        super.dismiss(animated: true, completion: completion)
    }
    
    @IBAction func exitTutorial() {
        let title = GDLocalizedString("tutorial.exit.alert_title")
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.cancel"), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: GDLocalizedString("general.alert.exit"), style: .destructive, handler: { (_) in
            // Make sure all of the delayed calls to play(...) end appropriately
            for step in self.steps ?? [] {
                if let page = step as? DestinationTutorialPage {
                    page.pageFinished = true
                }
            }
            
            NotificationCenter.default.removeObserver(self,
                                                      name: AVAudioSession.interruptionNotification,
                                                      object: AppContext.shared.audioEngine.session)
            
            if self.navigationController?.presentingViewController != nil {
                FirstUseExperience.setDidComplete(for: .beaconTutorial)
                self.dismiss(animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "ExitTutorialSegue", sender: self)
            }
            
            AppContext.shared.isInTutorialMode = false
            
            GDATelemetry.track("tutorial.beacon.exit")
            if GDATelemetry.helper?.tutorialBeaconStatus != "finished" {
                GDATelemetry.helper?.tutorialBeaconStatus = "exited"
            }
        }))
        
        present(alert, animated: true, completion: nil)
        
        // Save reference to alert
        presentedAlertController = alert
    }
}

extension DestinationTutorialViewController: CustomPageViewControllerDelegate {
    func pageChanged() {
        // Currently, we aren't changing any content when the page changes, so this impl is empty
    }
}

extension DestinationTutorialViewController: DestinationTutorialPageDelegate {
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
        goToNextPage()
    }
    
    func tutorialComplete() {
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
                                                  object: AppContext.shared.audioEngine.session)
        
        if self.navigationController?.presentingViewController != nil {
            FirstUseExperience.setDidComplete(for: .beaconTutorial)
            self.dismiss(animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "ExitTutorialSegue", sender: self)
        }
        
        GDATelemetry.track("tutorial.beacon.finished")
        GDATelemetry.helper?.tutorialBeaconStatus = "finished"
        GDATelemetry.helper?.tutorialBeaconCount += 1
    }
}
