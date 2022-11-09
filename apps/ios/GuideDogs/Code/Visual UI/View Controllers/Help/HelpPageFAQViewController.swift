//
//  HelpPageFAQViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class HelpPageFAQViewController: UIViewController {
    
    var faq: FAQ!
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerStubLabel: UILabel!
    
    @IBOutlet weak var answerStackView: UIStackView!
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = GDLocalizedString("faq.title.abbreviated")
        
        questionLabel.text = faq.question
        
        let para = faq.answer.split(separator: "\n").map({ return String($0) }).filter({ !$0.isEmpty })
        showParagraphs(stackView: answerStackView, stub: answerStubLabel, paragraphs: para)
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

extension HelpPageFAQViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}
