//
//  VirtualLocationViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine

class VirtualLocationViewController: UIViewController {
    
    enum State: Equatable {
        case orientation
        case edge(edge: RoadAdjacentDataView)
        case transition
        
        static func == (lhs: VirtualLocationViewController.State, rhs: VirtualLocationViewController.State) -> Bool {
            switch lhs {
            case .orientation:
                if case .orientation = rhs {
                    return true
                } else {
                    return false
                }
            case .edge(let lhsEdge):
                if case .edge(let rhsEdge) = rhs {
                    return lhsEdge == rhsEdge
                } else {
                    return false
                }
            case .transition:
                if case .transition = rhs {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var backLabel: UILabel!
    
    // MARK: Properties
    
    private var contentViewController: PreviewControlViewController?
    private var focusedEdgeSubscriber: AnyCancellable?
    private var isTransitioning = false
    private var focussedEdge: RoadAdjacentDataView?
    private var decisionPoint: IntersectionDecisionPoint?
    
    weak var behavior: PreviewBehavior<IntersectionDecisionPoint>? {
        didSet {
            guard oldValue?.id != behavior?.id else {
                return
            }
            
            // Stop updates from the current subscribter
            focusedEdgeSubscriber?.cancel()
            
            guard let behavior = behavior else {
                return
            }
            
            focusedEdgeSubscriber = behavior.currentlyFocussedRoad
                // Sends tuples of (currentlyFocussedRoad, isTransitioning, currentDecisionPoint)
                .combineLatest(behavior.isTransitioningSubject, behavior.currentDecisionPoint)
                // Make sure there is at least 0.5 sec between calls to configureView() so animations don't get messed up
                .throttle(for: 0.5, scheduler: RunLoop.main, latest: true)
                .sink(receiveValue: { [weak self] (newValue) in
                    guard let `self` = self else {
                        return
                    }
                    
                    // Save old values
                    let oldIsTransitioning = self.isTransitioning
                    
                    let (edge, isTransitioning, decisionPoint) = newValue
                    
                    // Save new values
                    self.isTransitioning = isTransitioning
                    self.focussedEdge = edge
                    self.decisionPoint = decisionPoint
                    
                    // If `isTransitioning` has changed, post a notification
                    // to ensure that Voiceover is aware of the new layout
                    self.configureView(postNotification: oldIsTransitioning != isTransitioning)
            })
        }
    }
    
    private var currentState: State {
        if isTransitioning {
            return .transition
        } else if let edge = focussedEdge {
            return .edge(edge: edge)
        } else {
            return .orientation
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewController = PreviewControlViewController()
        
        // Add new child view controller
        // to the container view
        self.add(viewController)
        self.contentView.addSubview(viewController.view)
        
        // Set layout for `child.view`
        viewController.view.frame = self.contentView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Ready to display
        viewController.didMove(toParent: self)
        
        // Ensure that Voiceover is aware of the new layout
        UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
        
        // Save reference to child view controller
        self.contentViewController = viewController
        self.contentViewController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure initial view
        configureView()
    }
    
    deinit {
        // Stop updates
        focusedEdgeSubscriber?.cancel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update back label appearance
        backLabel.layer.cornerRadius = backLabel.bounds.size.height / 2.0
        backLabel.layer.masksToBounds = true
        backLabel.layer.borderColor = backLabel.textColor.cgColor
        backLabel.layer.borderWidth = 0.75
        
        // Update view height
        let width = preferredContentSize.width
        let height = UIView.preferredContentHeightCompressedHeight(for: view)
        
        preferredContentSize = CGSize(width: width, height: height)
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if let container = container as? UIViewController, container == contentViewController {
            contentViewHeightConstraint.constant = container.preferredContentSize.height
        }
    }
    
    private func configureView(postNotification: Bool = false) {
        guard isViewLoaded else {
            return
        }
        
        self.startAnimation { [weak self] in
            guard let `self` = self else {
                return
            }
            
            // Configure the current location label
            if self.isTransitioning {
                // Approaching next decision point
                self.currentLocationLabel.text = GDLocalizedString("preview.approaching_intersection.label").uppercasedWithAppLocale()
            } else if let currentLocation = self.decisionPoint?.node.localizedName {
                // Display current location
                self.currentLocationLabel.text = GDLocalizedString("directions.at_poi", currentLocation).uppercasedWithAppLocale()
            } else {
                // Current location is unknown
                self.currentLocationLabel.text = GDLocalizedString("preview.current_intersection_unknown.label").uppercasedWithAppLocale()
            }
            
            // Configure content view controller
            self.contentViewController?.currentState = self.currentState
            
            if postNotification {
                self.view.layoutIfNeeded()
                // Ensure that Voiceover is aware of the new layout
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
            }
            
            self.view.layoutIfNeeded()
            
            self.stopAnimation()
        }
    }
    
    private func startAnimation(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.contentView.alpha = 0
        }, completion: { (_) in
            completion()
        })
    }
    
    private func stopAnimation() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.contentView.alpha = 1
        }
    }
    
    // MARK: `IBAction`
    
    @IBAction func onBackButtonTouchUpInside(_ sender: Any) {
        guard isTransitioning == false else {
            return
        }
        
        guard let behavior = self.behavior else {
            return
        }
        
        guard behavior.canGoToPrevious else {
            return
        }
        
        behavior.goToPrevious()
    }
    
}

extension VirtualLocationViewController: PreviewControlDelegate {
    
    func previewControl(_ viewController: PreviewControlViewController, didSelect edge: RoadAdjacentDataView?) {
        behavior?.select(edge)
    }
    
}
