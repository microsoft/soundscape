//
//  PreviewTutorialViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol PreviewTutorialDelegate: AnyObject {
    func previewTutorialDidComplete()
}

class PreviewTutorialViewController: UIViewController {
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    
    private var didMuteCallouts: Bool = false
    
    // MARK: Properties
    
    weak var delegate: PreviewTutorialDelegate?
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SettingsContext.shared.automaticCalloutsEnabled {
            didMuteCallouts = true
            SettingsContext.shared.automaticCalloutsEnabled = false
            AppContext.shared.eventProcessor.hush(playSound: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initialize gifs
        imageView1.image = UIImage(named: "Welcome1.gif")
        imageView2.image = UIImage(named: "Welcome2.gif")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if didMuteCallouts {
            SettingsContext.shared.automaticCalloutsEnabled = true
        }
    }
    
    // `IBAction`
    
    @IBAction private func onDoneTouchUpInside() {
        FirstUseExperience.setDidComplete(for: .previewTutorial)
        delegate?.previewTutorialDidComplete()
    }
    
}
