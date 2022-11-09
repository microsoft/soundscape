//
//  MainMenuView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class MenuView: DynamicView {

    lazy var backgroundOverlay: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = nil
        view.isAccessibilityElement = false
        return view
    }()
    
    lazy var menuBackdrop: UIView = {
        guard !UIAccessibility.isReduceTransparencyEnabled else {
            let background = UIView()
            background.translatesAutoresizingMaskIntoConstraints = false
            background.backgroundColor = Colors.Background.tertiary
            
            return background
        }
        
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        effect.translatesAutoresizingMaskIntoConstraints = false
        
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = .clear
        background.insertSubview(effect, at: 0)
        
        NSLayoutConstraint.activate([
            effect.topAnchor.constraint(equalTo: background.topAnchor),
            effect.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            effect.bottomAnchor.constraint(equalTo: background.bottomAnchor),
            effect.trailingAnchor.constraint(equalTo: background.trailingAnchor)
            ])
        
        return background
    }()
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var topView: MenuTopView = {
        let view = MenuTopView()
        return view
    }()
    
    lazy var crosscheckButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = Colors.Background.primary
        button.layer.cornerRadius = 5.0
        button.showsTouchWhenHighlighted = true
        button.accessibilityLabel = GDLocalizedString("troubleshooting.check_audio")
        button.accessibilityHint = GDLocalizedString("troubleshooting.check_audio.hint")
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = GDLocalizedString("troubleshooting.check_audio")
        label.textColor = Colors.Foreground.primary
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        
        button.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: button.topAnchor, constant: 12.0),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 12.0),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12.0),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12.0),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 80.0)
            ])
        
        return button
    }()
    
    private(set) var items: [DynamicMenuItemView] = []
    
    private var bottomConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        // Disable smart invert since this UI is already light foreground on dark background
        accessibilityIgnoresInvertColors = true
        
        translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(topView)
        menuBackdrop.addSubview(scrollView)
        menuBackdrop.addSubview(crosscheckButton)
        addSubview(menuBackdrop)
        addSubview(backgroundOverlay)
        
        menuBackdrop.layer.cornerRadius = 20.0
        
        bottomConstraint = topView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        
        // Setup the layout constraints
        NSLayoutConstraint.activate([
            menuBackdrop.topAnchor.constraint(equalTo: topAnchor),
            menuBackdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            menuBackdrop.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0.0),
            menuBackdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundOverlay.topAnchor.constraint(equalTo: topAnchor),
            backgroundOverlay.leadingAnchor.constraint(equalTo: menuBackdrop.trailingAnchor),
            backgroundOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: menuBackdrop.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: menuBackdrop.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: crosscheckButton.topAnchor, constant: -12.0),
            crosscheckButton.bottomAnchor.constraint(equalTo: menuBackdrop.bottomAnchor, constant: -24.0),
            crosscheckButton.leadingAnchor.constraint(equalTo: menuBackdrop.leadingAnchor, constant: 12.0),
            crosscheckButton.trailingAnchor.constraint(equalTo: menuBackdrop.trailingAnchor, constant: -12.0),
            topView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            topView.leadingAnchor.constraint(equalTo: menuBackdrop.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            topView.trailingAnchor.constraint(equalTo: menuBackdrop.trailingAnchor),
            topView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16.0),
            bottomConstraint
        ])
        
        accessibilityViewIsModal = true
    }
    
    func addMenuItem(_ item: MenuItem) {
        addMenuItem(DynamicMenuItemView(item, alternateBackground: items.count % 2 == 0))
    }
    
    private func addMenuItem(_ item: DynamicMenuItemView) {
        // Add the menu item and set up the proper constraints
        let previous = items.last ?? topView
        
        scrollView.addSubview(item)
        items.append(item)
        
        item.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        item.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        item.topAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
        
        bottomConstraint.isActive = false
        bottomConstraint = item.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        bottomConstraint.isActive = true
    }
}
