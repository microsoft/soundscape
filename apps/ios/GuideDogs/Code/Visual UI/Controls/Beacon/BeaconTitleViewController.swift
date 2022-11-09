//
//  BeaconTitleViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

struct BeaconTitleViewRepresentable: UIViewControllerRepresentable {
    
    // MARK: `UIViewControllerRepresentable`
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = BeaconTitleViewController(nibName: "BeaconTitleView", bundle: Bundle.main)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
    
}

class BeaconTitleViewController: UIViewController {
    
    // MARK: `IBOutlet`
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleContainerView: UIView!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var subtitleImageView: UIImageView!
    @IBOutlet private var beaconLabel: UILabel!
    
    // MARK: Properties
    
    private var userLocationStore = UserLocationStore()
    private var beaconDetailStore = BeaconDetailStore()
    private var listeners: [AnyCancellable] = []
    private var beaconDetail: BeaconDetail?
    private var userLocation: CLLocation?
    private var timer: Timer?
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let view = view as? BeaconTitleContentView {
            view.delegate = self
        }
        
        // Configure initial view
        configureView()
        configureAccessibilityActions()
        configureTimer()
        
        // Listen for location updates
        listeners.append(userLocationStore.$location
                            .receive(on: DispatchQueue.main)
                            .sink(receiveValue: { [weak self] newValue in
            guard let `self` = self else {
                return
            }
            
            guard self.view.accessibilityElementIsFocused() == false else {
                return
            }
            
            // Save new value
            self.userLocation = newValue
            
            self.configureView()
        }))
        
        // Listen for beacon updates
        listeners.append(beaconDetailStore.$beacon
                            .receive(on: DispatchQueue.main)
                            .sink(receiveValue: { [weak self] newValue in
            guard let `self` = self else {
                return
            }
            
            guard self.view.accessibilityElementIsFocused() == false else {
                return
            }
            
            let oldValue = self.beaconDetail
            
            // Save new value
            self.beaconDetail = newValue
            
            // If the selected location on the underlying entity has changed, reconfigure the view
            // to show the new distance
            let beaconCoordinateDidChange = newValue?.locationDetail.location.coordinate != oldValue?.locationDetail.location.coordinate
            
            // If the underlying entity has changed, reconfigure the view and the view's accessibility
            // actions
            let beaconDidChange = newValue?.locationDetail.source != oldValue?.locationDetail.source
            
            // If the route has changed, reconfigure the view and the view's accessibility actions
            let routeDidChange = newValue?.routeDetail?.id != oldValue?.routeDetail?.id
            
            if beaconCoordinateDidChange || beaconDidChange || routeDidChange {
                self.configureView()
            }
            
            if beaconDidChange || routeDidChange {
                self.configureAccessibilityActions()
            }
            
            // If necessary, schedule or invalidate the timer used to update the elapsed time view
            self.configureTimer()
        }))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        listeners.cancelAndRemoveAll()
        // Reset timer
        timer?.invalidate()
        timer = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = preferredContentSize.width
        let height = UIView.preferredContentHeightCompressedHeight(for: view)
        
        preferredContentSize = CGSize(width: width, height: height)
    }
    
    // MARK: View Configuration
    
    private func configureTimer() {
        if let routeDetail = beaconDetail?.routeDetail, let route = routeDetail.guidance, route.progress.isDone == false {
            if let timer = timer, timer.isValid {
                // Timer is already running
                return
            }
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                
                guard self.view.accessibilityElementIsFocused() == false else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.configureView()
                }
            }
        } else {
            // Reset timer
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func configureView() {
        
        guard isViewLoaded else {
            return
        }
        
        if let beacon = beaconDetail {
            // Configure title label
            let titleLabel = beacon.labels.title
            
            self.titleLabel.text = titleLabel.text
            self.titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
            self.titleLabel.textColor = UIColor(named: "Foreground 2")
            
            // Configure subtitle label
            let timeLabel = beacon.labels.time
            
            if let timeLabel = timeLabel {
                subtitleContainerView.isHidden = false
                subtitleImageView.image = UIImage(systemName: "timer")
                subtitleImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: UIFont.preferredFont(forTextStyle: .footnote), scale: .small)
                subtitleImageView.tintColor = UIColor(named: "Highlight Yellow")
                subtitleLabel.text = timeLabel.text
                subtitleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
                subtitleLabel.textColor = UIColor(named: "Highlight Yellow")
            } else {
                subtitleContainerView.isHidden = true
            }
            
            // Configure beacon label
            let nLabel = beacon.labels.name
            let dLabel = beacon.labels.distance(from: userLocation)
            // Appending labels
            let aLabel = nLabel.appending(dLabel, localizedSeparator: "・")
            
            let attributedString = NSMutableAttributedString(string: aLabel.text)
            
            let nAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor(named: "Foreground 1")!
            ]
            
            let dAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .foregroundColor: UIColor(named: "Highlight Yellow")!
            ]
            
            attributedString.addAttributes(nAttributes, range: NSRange(location: 0, length: nLabel.text.count))
            attributedString.addAttributes(dAttributes, range: NSRange(location: nLabel.text.count, length: aLabel.text.count - nLabel.text.count))
            
            beaconLabel.attributedText = attributedString
            
            // Configure accessibility labels
            if let timeLabel = timeLabel {
                view.accessibilityLabel = beacon.routeDetail == nil ? aLabel.accessibilityText : titleLabel.appending(aLabel).appending(timeLabel).accessibilityText
            } else {
                view.accessibilityLabel = beacon.routeDetail == nil ? aLabel.accessibilityText
                : titleLabel.appending(aLabel).accessibilityText
            }
            
            view.accessibilityHint = GDLocalizedString("beacon.action.mute_unmute_beacon.acc_hint")
        } else {
            // Remove text from labels
            self.titleLabel.text = nil
            subtitleContainerView.isHidden = true
            beaconLabel.text = nil
            
            // Remove accessibility labels
            view.accessibilityLabel = nil
            view.accessibilityHint = nil
        }
        
        view.layoutIfNeeded()
    }
    
    private func configureAccessibilityActions() {
        guard isViewLoaded else {
            return
        }
        
        view.accessibilityCustomActions?.removeAll()
        
        guard let beacon = beaconDetail else {
            return
        }
        
        var actions: [UIAccessibilityCustomAction] = []
        
        if let routeDetail = beacon.routeDetail {
            let name: String
            
            switch routeDetail.source {
            case .trailActivity: name = GDLocalizedString("route_detail.action.stop_event")
            case .database: name = GDLocalizedString("route_detail.action.stop_route")
            case .cache: name = GDLocalizedString("route_detail.action.stop_route")
            }
            
            // Stop route or activity
            actions.append(UIAccessibilityCustomAction(name: name, actionHandler: { _ in
                guard AppContext.shared.eventProcessor.isCustomBehaviorActive else {
                    return false
                }
                
                AppContext.shared.eventProcessor.deactivateCustom()
                return true
            }))
            
            // Default beacon actions
            actions.append(contentsOf: [
                .callout(beacon),
                .toggleAudio(beacon),
                .moreInformation(beacon, userLocation: self.userLocation)
            ])
        } else {
            // Save marker
            if beacon.locationDetail.isMarker == false {
                actions.append(UIAccessibilityCustomAction(name: BeaconAction.createMarker.text) { [weak self] _ in
                    guard let `self` = self else {
                        return false
                    }
                    
                    guard let viewController = BeaconActionHandler.createMarker(detail: beacon) else {
                        return false
                    }
                    
                    self.navigationController?.pushViewController(viewController, animated: true)
                    
                    return true
                })
            }
            
            // Default beacon actions
            actions.append(contentsOf: [
                .callout(beacon),
                .toggleAudio(beacon),
                .moreInformation(beacon, userLocation: self.userLocation)
            ])
            
            // Remove beacon
            actions.append(UIAccessibilityCustomAction(name: BeaconAction.remove(source: nil).text, actionHandler: { _ in
                BeaconActionHandler.remove(detail: beacon)
                
                return true
            }))
        }
        
        view.accessibilityCustomActions = actions
    }
}

extension BeaconTitleViewController: BeaconTitleContentViewDelegate {
    
    func onAccessibilityElementDidLoseFocus() {
        DispatchQueue.main.async {
            self.configureView()
            self.configureAccessibilityActions()
        }
    }
    
    func onAccessibilityActivate() {
        BeaconActionHandler.toggleAudio()
    }
    
}

private extension UIAccessibilityCustomAction {
    
    static func callout(_ beacon: BeaconDetail) -> UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: BeaconAction.callout.text, actionHandler: { _ in
            BeaconActionHandler.callout(detail: beacon)
            
            return true
        })
    }
    
    static func toggleAudio(_ beacon: BeaconDetail) -> UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: BeaconAction.toggleAudio.text, actionHandler: { _ in
            BeaconActionHandler.toggleAudio()
            
            return true
        })
    }
    
    static func moreInformation(_ beacon: BeaconDetail, userLocation: CLLocation?) -> UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: BeaconAction.moreInformation.text, actionHandler: { _ in
            BeaconActionHandler.moreInformation(detail: beacon, userLocation: userLocation)
            
            return true
        })
    }
    
}
