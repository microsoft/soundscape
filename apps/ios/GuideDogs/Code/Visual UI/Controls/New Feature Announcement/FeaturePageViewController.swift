//
//  RecentHistoryFeatureViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class FeaturePageViewController: UIViewController {

    @IBOutlet weak var featureImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var featureImageViewHeightConstraint: NSLayoutConstraint!
    
    var image: UIImage?
    var header: String!
    var attributedBody: NSMutableAttributedString!
    var bodyAccessibilityLabel: String!
    var contentView: UIView!
    var buttonLabel: String?
    var buttonAccessibilityHint: String?
    
    class func create(feature: FeatureInfo) -> FeaturePageViewController {
        let vc = FeaturePageViewController(nibName: "FeaturePageView", bundle: nil)
        
        vc.image = feature.localizedImage
        vc.header = feature.localizedTitle
        vc.bodyAccessibilityLabel = feature.localizedAccessibilityDescription.accessibilityString()
        
        let description = feature.localizedDescription
        vc.attributedBody = NSMutableAttributedString(string: description)
        vc.attributedBody.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: description.count))
        vc.attributedBody.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: description.count))
        
        if let start = feature.hyperlinkStart, let length = feature.hyperlinkLength, let url = feature.hyperlinkURL {
            vc.attributedBody.addAttribute(.link, value: url, range: NSRange(location: start, length: length))
        }
        
        // Save custom label for the "next" / "done" button
        vc.buttonLabel = feature.buttonLabel
        vc.buttonAccessibilityHint = feature.buttonAccessibilityHint
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        featureImageView.image = image
        headerLabel.text = header
        headerLabel.accessibilityLabel = header.accessibilityString()
        bodyTextView.attributedText = attributedBody
        bodyTextView.attributedText.accessibilityLabel = bodyAccessibilityLabel
        
        bodyTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        bodyTextView.textContainer.lineFragmentPadding = 0
        
        if featureImageView.image == nil {
            // Hide image view
            featureImageViewHeightConstraint.constant = 0.0
        } else {
            featureImageViewHeightConstraint.constant = 283.0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bodyTextView.sizeToFit()
        
        if image == nil {
            // If there is no image, increase the text view to cover the gradient
            textViewHeightConstraint.constant = bodyTextView.height + 500
        } else {
            textViewHeightConstraint.constant = bodyTextView.height
        }
    }
    
}

extension FeaturePageViewController: UITextViewDelegate {
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return false
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    
}
