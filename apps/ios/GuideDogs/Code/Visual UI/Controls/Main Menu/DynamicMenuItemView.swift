//
//  DynamicMenuItemView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class DynamicMenuItemView: DynamicView {
    
    private var alternateBackground = false
    private(set) var menuItem: MenuItem?
    
    lazy var label: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = UIFont.preferredFont(forTextStyle: .title3)
        view.adjustsFontForContentSizeCategory = true
        view.textColor = Colors.Foreground.primary
        view.numberOfLines = 0
        view.textAlignment = .left
        view.isAccessibilityElement = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    lazy var iconContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isAccessibilityElement = false
        container.setContentHuggingPriority(.required, for: .horizontal)
        return container
    }()
    
    lazy var icon: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.adjustsImageSizeForAccessibilityContentSizeCategory = true
        view.isAccessibilityElement = false
        view.tintColor = .white
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: UIFont.preferredFont(forTextStyle: .body))
        return view
    }()
    
    lazy var button: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isAccessibilityElement = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    convenience init(_ item: MenuItem, alternateBackground: Bool = true) {
        self.init(frame: .zero)
        
        icon.image = item.icon
        label.text = item.localizedString
        button.accessibilityLabel = item.accessibilityString
        menuItem = item
        self.alternateBackground = alternateBackground
        
        setAccessibilityVariations(traitCollection.preferredContentSizeCategory.isAccessibilityCategory)
    }
    
    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Add the subviews
        addSubview(label)
        addSubview(iconContainer)
        iconContainer.addSubview(icon)
        addSubview(button)
        
        let widthConst = label.widthAnchor.constraint(equalTo: self.widthAnchor)
        widthConst.priority = .defaultLow
        
        // Activate the common layout constraints
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.heightAnchor.constraint(equalTo: icon.widthAnchor, multiplier: 1.0),
            iconContainer.widthAnchor.constraint(greaterThanOrEqualTo: icon.widthAnchor),
            iconContainer.heightAnchor.constraint(greaterThanOrEqualTo: icon.heightAnchor),
            iconContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 28.0),
            iconContainer.heightAnchor.constraint(equalTo: iconContainer.widthAnchor, multiplier: 1.0),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0),
            trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 20.0),
            trailingAnchor.constraint(equalTo: button.trailingAnchor),
            bottomAnchor.constraint(equalTo: button.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            widthConst
        ])
        
        // Setup the dynamic layout constraints
        let normal: [NSLayoutConstraint] = [
            iconContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 18),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20.0)
        ]
        
        let large: [NSLayoutConstraint] = [
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            label.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 20.0)
        ]
        
        setupDynamicLayoutConstraints(normal, large)
    }
    
    override func updateLayoutConstraints(_ forAccessibilityCategory: Bool) {
        super.updateLayoutConstraints(forAccessibilityCategory)
        setAccessibilityVariations(forAccessibilityCategory)
    }
    
    private func setAccessibilityVariations(_ enabled: Bool) {
        if enabled {
            backgroundColor = alternateBackground ? Colors.Background.menuAlternate : nil
            label.textAlignment = .center
        } else {
            backgroundColor = nil
            label.textAlignment = .left
        }
    }
}
