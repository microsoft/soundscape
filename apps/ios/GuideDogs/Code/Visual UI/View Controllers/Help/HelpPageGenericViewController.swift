//
//  HelpPageGenericViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class HelpPageGenericViewController: UIViewController {
    
    var content: TextHelpPage!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var stubLabel: UILabel!
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet weak var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showParagraphs(stackView: stackView, stub: stubLabel, paragraphs: content.text)
    }
    
    func loadContent(_ content: TextHelpPage) {
        title = content.title
        
        if content.title.lowercased().contains("callout") {
            let titleLabel = UILabel(frame: CGRect.zero)
            titleLabel.text = content.title
            titleLabel.accessibilityLabel = content.title.lowercased().replacingOccurrences(of: "callout", with: "call out")
            titleLabel.textColor = UIColor.white
            titleLabel.textAlignment = .natural
            titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
            
            navigationItem.titleView = titleLabel
        }
        
        self.content = content
    }
    
    func showParagraphs(stackView: UIStackView, stub: UILabel, paragraphs: [String]) {
        stub.attributedText = paragraphs.first?.getFormattedString() ?? NSAttributedString(string: GDLocalizedString("text.coming_soon"))
        stub.accessibilityLabel = paragraphs.first?.getVoiceOverLabel()
        
        guard paragraphs.count > 1 else {
            return
        }
        
        for paragraph in paragraphs.suffix(from: 1) {
            let label = UILabel(frame: CGRect.zero)
            label.attributedText = paragraph.getFormattedString()
            label.accessibilityLabel = paragraph.getVoiceOverLabel()
            label.numberOfLines = 0
            
            stackView.addArrangedSubview(label)
        }
    }
}

extension HelpPageGenericViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}
