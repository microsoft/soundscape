//
//  MenuTopView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class MenuTopView: UIView {
    
    lazy var closeIcon: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.adjustsImageSizeForAccessibilityContentSizeCategory = true
        view.isAccessibilityElement = false
        return view
    }()
    
    lazy var closeButton: UIButton = {
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
    
    convenience init() {
        self.init(frame: .zero)
        closeIcon.image = MenuItem.home.icon!
    }
    
    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Add the subviews
        addSubview(closeIcon)
        addSubview(closeButton)
        
        // Activate the common layout constraints
        NSLayoutConstraint.activate([
            closeIcon.heightAnchor.constraint(equalTo: closeIcon.widthAnchor, multiplier: 1.0),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16.0),
            closeIcon.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 16.0),
            closeButton.trailingAnchor.constraint(greaterThanOrEqualTo: closeIcon.trailingAnchor, constant: 16.0),
            closeIcon.topAnchor.constraint(equalTo: closeButton.topAnchor, constant: 16.0),
            closeButton.bottomAnchor.constraint(equalTo: closeIcon.bottomAnchor, constant: 16.0)
        ])
        
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

}
