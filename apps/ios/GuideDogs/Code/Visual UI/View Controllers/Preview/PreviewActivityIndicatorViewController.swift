//
//  PreviewActivityIndicatorViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class PreviewActivityIndicatorViewController: UIViewController {
    
    enum State {
        case activating(progress: Progress?)
        case deactivating
        
        var localizedString: String {
            switch self {
            case .activating: return GDLocalizedString("general.loading.start")
            case .deactivating: return GDLocalizedString("general.loading.end")
            }
        }
    }
    
    // MARK: `IBOutlet`
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressViewLabel: UILabel!
    
    // MARK: Properties
    
    private var token: NSKeyValueObservation?
    
    var state: State = .activating(progress: nil) {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            configureView(for: state)
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initialize image view
        imageView.image = UIImage(named: "travel1")!
        // Initialize image view animations
        imageView.animationDuration = 1.0
        imageView.animationImages = [
            UIImage(named: "travel2")!,
            UIImage(named: "travel3")!,
            UIImage(named: "travel4")!,
            UIImage(named: "travel5")!
        ]
        
        // Start animations
        imageView.startAnimating()
        
        // Configure progress view
        configureView(for: state)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop animations
        imageView.stopAnimating()
        
        // Stop observing updates
        token?.invalidate()
        token = nil
    }
    
    private func configureView(for state: State) {
        progressViewLabel.text = state.localizedString
        
        if case .activating(let aProgress) = state, let progress = aProgress {
            // Show `progressView`
            progressView.progress = Float(progress.fractionCompleted)
            progressView.isHidden = false
            
            // Start observing progress updates
            token = progress.observe(\.completedUnitCount, changeHandler: { (progress, _) in
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
            })
        } else {
            // Stop observing updates
            token?.invalidate()
            token = nil
            
            // Hide the progress view when there are
            // no updates
            progressView.isHidden = true
        }
    }
    
}
