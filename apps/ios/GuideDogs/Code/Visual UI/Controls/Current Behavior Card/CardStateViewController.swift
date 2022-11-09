//
//  CardStateViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit
import CoreLocation
import SwiftUI

class CardStateViewController: UIViewController {
    
    enum Segue {
        case flagDetailView
        
        var identifier: String {
            switch self {
            case .flagDetailView: return "FlagDetailView"
            }
        }
    }
    
    private enum State {
        case `default`
        case beacon
        case route
        case tour
        
        var viewController: UIViewController? {
            switch self {
            case .default:
                let storyboard = UIStoryboard(name: "main", bundle: Bundle.main)
                return storyboard.instantiateViewController(withIdentifier: "RecommenderViewHostingController")
            case .beacon, .route:
                let storyboard = UIStoryboard(name: "main", bundle: Bundle.main)
                return storyboard.instantiateViewController(withIdentifier: "BeaconViewHostingController")
            case .tour:
                let storyboard = UIStoryboard(name: "main", bundle: Bundle.main)
                return storyboard.instantiateViewController(withIdentifier: "TourCardContainerHost")
            }
        }
    }
    
    // MARK: Properties
    
    private(set) var currentVC: UIViewController?
    private var behaviorActivatedObserver: NSObjectProtocol?
    private var behaviorDeactivatedObserver: NSObjectProtocol?
    private var beaconChangedObserver: NSObjectProtocol?
    
    private var state: State = .default {
        didSet {
            transition(to: state)
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure the initial state
        if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance {
            state = .route
        } else if AppContext.shared.eventProcessor.activeBehavior is GuidedTour {
            state = .tour
        } else if AppContext.shared.spatialDataContext.destinationManager.isDestinationSet {
            state = .beacon
        } else {
            state = .default
        }
        
        behaviorActivatedObserver = NotificationCenter.default.addObserver(forName: Notification.Name.behaviorActivated, object: AppContext.shared.eventProcessor, queue: OperationQueue.main) { [weak self] (_) in
            if AppContext.shared.eventProcessor.activeBehavior is RouteGuidance {
                self?.state = .route
            }
            
            if AppContext.shared.eventProcessor.activeBehavior is GuidedTour {
                self?.state = .tour
            }
        }
        
        behaviorDeactivatedObserver = NotificationCenter.default.addObserver(forName: Notification.Name.behaviorDeactivated, object: AppContext.shared.eventProcessor, queue: OperationQueue.main) { [weak self] (_) in
            if AppContext.shared.spatialDataContext.destinationManager.isDestinationSet {
                self?.state = .beacon
            } else {
                // Remove the child view controller
                self?.state = .default
            }
        }
        
        beaconChangedObserver = NotificationCenter.default.addObserver(forName: Notification.Name.destinationChanged, object: AppContext.shared.spatialDataContext.destinationManager, queue: OperationQueue.main) { [weak self] (notification) in
            guard AppContext.shared.eventProcessor.activeBehavior is SoundscapeBehavior else {
                return
            }
            
            // Show the destination view if the destination has been set from a different location
            if AppContext.shared.spatialDataContext.destinationManager.isDestinationSet {
                self?.state = .beacon
                
                return
            }
            
            // Hide destination view and return if destination does not exist
            
            guard self?.currentVC is BeaconViewHostingController else {
                return
            }
            
            // Remove the child view controller
            self?.state = .default
            
            UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let token = behaviorActivatedObserver {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let token = behaviorDeactivatedObserver {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let token = beaconChangedObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container is BeaconViewHostingController, currentVC is BeaconViewHostingController {
            preferredContentSize.height = container.preferredContentSize.height
        }
        
        if container is RecommenderViewHostingController, currentVC is RecommenderViewHostingController {
            preferredContentSize.height = container.preferredContentSize.height
        }
        
        if container is TourCardContainerHostingController, currentVC is TourCardContainerHostingController {
            preferredContentSize.height = container.preferredContentSize.height
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LocationDetailViewController {
            guard let detail = sender as? LocationDetail else {
                return
            }
            
            vc.locationDetail = detail
            
            // Setup the back button for the details page
            let backItem = UIBarButtonItem()
            backItem.title = GDLocalizedString("ui.back_button.title")
            navigationItem.backBarButtonItem = backItem
        }
    }
    
    func performSegue(_ segue: Segue, sender: Any?) {
        self.performSegue(withIdentifier: segue.identifier, sender: sender)
    }
    
    // MARK: Child View Controller Management
    
    private func transition(to state: State) {
        currentVC?.remove()
        
        guard let childVC = state.viewController else {
            return
        }
        
        // Add the child VC and make sure its view fills the full view of this VC
        add(childVC) { [weak self] (childView) -> [NSLayoutConstraint] in
            guard let strongSelf = self else {
                return []
            }
            
            var constraints: [NSLayoutConstraint] = []
            
            constraints.append(NSLayoutConstraint(item: childView, attribute: .leading, relatedBy: .equal, toItem: strongSelf.view, attribute: .leading, multiplier: 1, constant: 0))
            constraints.append(NSLayoutConstraint(item: childView, attribute: .trailing, relatedBy: .equal, toItem: strongSelf.view, attribute: .trailing, multiplier: 1, constant: 0))
            constraints.append(NSLayoutConstraint(item: childView, attribute: .top, relatedBy: .equal, toItem: strongSelf.view, attribute: .top, multiplier: 1, constant: 0))
            constraints.append(NSLayoutConstraint(item: childView, attribute: .bottom, relatedBy: .equal, toItem: strongSelf.view, attribute: .bottom, multiplier: 1, constant: 0))
            
            return constraints
        }
        
        currentVC = childVC
    }

}
