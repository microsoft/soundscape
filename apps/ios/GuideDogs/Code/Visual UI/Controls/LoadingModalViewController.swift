//
//  LoadingModalViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

class LoadingModalViewController: UIViewController {
    var loadingMessage: String = GDLocalizedString("general.loading.loading") {
        didSet {
            guard let loadingMessageLabel = loadingMessageLabel else {
                return
            }
            
            loadingMessageLabel.text = loadingMessage
            activityIndicatorView.accessibilityLabel = loadingMessage
        }
    }
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var loadingMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingMessageLabel.text = loadingMessage
        activityIndicatorView.accessibilityLabel = loadingMessage
        
        loadingMessageLabel.isAccessibilityElement = false
    }
}
