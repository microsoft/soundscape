//
//  PreviewControlView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol PreviewControlDelegate: AnyObject {
    func previewControl(_ viewController: PreviewControlViewController, didSelect edge: RoadAdjacentDataView?)
}

class PreviewControlViewController: UIViewController {
    
    typealias State = VirtualLocationViewController.State
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var labelContainerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    // MARK: Properties
    
    weak var delegate: PreviewControlDelegate?
    private var headingSubscriber: Heading?
    
    var currentState: State = .orientation {
        didSet {
            guard oldValue != currentState else {
                return
            }
            
            guard isViewLoaded else {
                return
            }
            
            configureView()
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for heading updates from the device
        headingSubscriber = AppContext.shared.geolocationManager.heading(orderedBy: [.device])
        
        // Start heading updates
        headingSubscriber?.onHeadingDidUpdate { [weak self] (newHeadingValue) in
            guard let `self` = self else {
                return
            }
            
            guard let newValue = newHeadingValue?.value else {
                return
            }
            
            guard case .orientation = self.currentState else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.configureView(for: newValue)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure initial view
        configureView()
        
        // Calculated preferred height for the child view controller
        let preferredContentHeight = UIView.preferredContentHeight(for: view)
        view.setHeight(preferredContentHeight)
    }
    
    deinit {
        // Stop heading updates
        headingSubscriber?.onHeadingDidUpdate(nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = preferredContentSize.width
        let height = UIView.preferredContentHeightCompressedHeight(for: view)
        
        preferredContentSize = CGSize(width: width, height: height)
    }
    
    // MARK: Manage State
    
    private func resetView() {
        // Reset transformation
        button.transform = CGAffineTransform.identity
        
        // Reset image view
        button.imageView?.image = nil
        button.imageView?.stopAnimating()
        button.imageView?.animationImages = nil
    }
    
    private func configureView() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            // Reset the current view
            self.resetView()
            
            switch self.currentState {
            case .orientation:
                // Initialize image view
                self.button.imageView?.image = UIImage(named: "preview_arrow")!
                
                // Configure initial view
                self.configureView(for: self.headingSubscriber?.value ?? 0.0)
            case .edge(let edge):
                // Initialize image view
                self.button.imageView?.image = UIImage(named: "go_animation1")!
                // Initialize image view animations
                self.button.imageView?.animationDuration = 1.0
                self.button.imageView?.animationImages = [
                    UIImage(named: "go_animation2")!,
                    UIImage(named: "go_animation3")!,
                    UIImage(named: "go_animation4")!,
                    UIImage(named: "go_animation5")!
                ]
                
                // Start animations
                self.button.imageView?.startAnimating()
                
                let edgeDirection = edge.direction.bearing
                
                // Initialize title
                let titleText: String
                let titleAccessibilityText: String
                
                if let cDirection = CardinalDirection(direction: edgeDirection) {
                    titleText = GDLocalizedString("preview.content.edge.text", cDirection.localizedAbbreviatedString, edge.direction.road.localizedName)
                    titleAccessibilityText = GDLocalizedString("preview.content.edge.text", cDirection.localizedString, edge.direction.road.localizedName)
                } else {
                    titleText = edge.direction.road.localizedName
                    titleAccessibilityText = edge.direction.road.localizedName
                }
                
                // Initialize subtitle
                let subtitleText = GDLocalizedString("preview.next_intersection.label", edge.endpoint.localizedName)
                
                // Initialize accessibility label
                let accessibilityLabel = "\(titleAccessibilityText)\n\(subtitleText)"
                
                // Show labels
                self.configureLabelView(titleText: titleText, subtitleText: subtitleText, accessibilityLabel: accessibilityLabel)
            case .transition:
                // Initialize image view
                self.button.imageView?.image = UIImage(named: "travel1")!
                // Initialize image view animations
                self.button.imageView?.animationDuration = 1.0
                self.button.imageView?.animationImages = [
                    UIImage(named: "travel2")!,
                    UIImage(named: "travel3")!,
                    UIImage(named: "travel4")!,
                    UIImage(named: "travel5")!
                ]
                
                // Start animations
                self.button.imageView?.startAnimating()
                
                // Hide labels
                self.configureLabelView(titleText: nil, subtitleText: nil, accessibilityLabel: nil)
            }
        }
    }
    
    private func configureView(for heading: Double) {
        let text: String
        let accessibilityLabel: String
        
        let headingInt = Int(heading.rounded(.toNearestOrEven))
        let headingStr = String(headingInt)
        
        if FeatureFlag.isEnabled(.developerTools) {
            if let cDirection = CardinalDirection(direction: heading) {
                text = GDLocalizedString("preview.content.orientation.text.with_cardinal", headingStr, cDirection.localizedAbbreviatedString)
                accessibilityLabel = GDLocalizedString("preview.content.orientation.text.with_cardinal", headingStr, cDirection.localizedString)
            } else {
                text = GDLocalizedString("preview.content.orientation.text.without_cardinal", headingStr)
                accessibilityLabel = GDLocalizedString("preview.content.orientation.text.without_cardinal", headingStr)
            }
        } else {
            // In release builds, display a prompt encouraging the user to rotate the phone
            text = GDLocalizedString("preview.callout.road_finder.instructions")
            accessibilityLabel = GDLocalizedString("preview.callout.road_finder.instructions")
        }
        
        // Show heading in the title label
        configureLabelView(titleText: text, subtitleText: nil, accessibilityLabel: accessibilityLabel)
        
        // Rotate the image view
        let angleInRadians = Measurement(value: heading, unit: UnitAngle.degrees).converted(to: .radians).value
        self.button.transform = CGAffineTransform(rotationAngle: CGFloat(angleInRadians))
    }
    
    private func configureLabelView(titleText: String?, subtitleText: String?, accessibilityLabel: String?) {
        // If there is no text to display, use whitespace to maintain the vertical
        // spacing
        titleLabel.text = titleText ?? " "
        subtitleLabel.text = subtitleText ?? " "
        
        if let accessibilityLabel = accessibilityLabel {
            // Present both labels as a single accessibility element
            labelContainerView.accessibilityLabel = accessibilityLabel
            labelContainerView.accessibilityElementsHidden = false
        } else {
            // Hide the labels
            labelContainerView.accessibilityLabel = nil
            labelContainerView.accessibilityElementsHidden = true
        }
    }
    
    // MARK: `IBAction`
    
    @IBAction private func onButtonTouchUpInside(_ sender: UIButton) {
        var selectedEdge: RoadAdjacentDataView?
        
        if case .edge(let edge) = currentState {
            selectedEdge = edge
        }
        
        delegate?.previewControl(self, didSelect: selectedEdge)
    }
    
}
