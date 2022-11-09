//
//  FilterTableViewHeaderView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol FilterTableViewHeaderViewDelegate: AnyObject {
    var isEnabled: Bool { get }
    func didSelect(action: FilterTableViewHeaderView.Action)
}

class FilterTableViewHeaderView: UITableViewHeaderFooterView, NibLoadableView {
    
    enum Action: CaseIterable {
        case clear
        case set
        
        init?(localizedTitle: String) {
            guard let value = Action.allCases.first(where: { $0.localizedTitle == localizedTitle }) else {
                return nil
            }
            
            self = value
        }
        
        var localizedTitle: String {
            switch self {
            case .clear: return GDLocalizedString("filter.clear.capital")
            case .set: return GDLocalizedString("filter.set")
            }
        }
        
        var localizedAccessibilityHint: String {
            switch self {
            case .clear: return GDLocalizedString("filter.clear.hint")
            case .set: return GDLocalizedString("filter.double_tap_places_category")
            }
        }
    }
    
    // MARK: Properties
    
    weak var delegate: FilterTableViewHeaderViewDelegate?
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: View Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Initialize tap gesture
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onActionButtonTouchUpInside))
        
        // If VoiceOver is running, add tap gesture
        if UIAccessibility.isVoiceOverRunning {
            self.addGestureRecognizer(tapGestureRecognizer)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAccessibilityVoiceOverStatusChanged), name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
    }
    
    // MARK: Notifications
    
    @objc private func onAccessibilityVoiceOverStatusChanged() {
        if UIAccessibility.isVoiceOverRunning {
            self.addGestureRecognizer(tapGestureRecognizer)
        } else {
            self.removeGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    // MARK: Actions
    
    @IBAction func onActionButtonTouchUpInside() {
        guard let localizedTitle = actionButton.currentTitle else {
            return
        }
        
        guard let action = Action(localizedTitle: localizedTitle) else {
            return
        }
        
        delegate?.didSelect(action: action)
    }

}
