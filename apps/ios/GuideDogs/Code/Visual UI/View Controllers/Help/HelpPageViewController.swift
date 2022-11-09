//
//  HelpPageViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class HelpPageViewController: UIViewController {

    var what: [String] = []
    var how: [String] = []
    var when: [String] = []
    var link: SectionedHelpPageDeepLink?
    
    @IBOutlet weak var whatStubLabel: UILabel!
    @IBOutlet weak var whenStubLabel: UILabel!
    @IBOutlet weak var howStubLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var whatStackView: UIStackView!
    @IBOutlet weak var whenStackView: UIStackView!
    @IBOutlet weak var howStackView: UIStackView!
    @IBOutlet weak var linkButton: UIButton!
    
    @IBOutlet weak var largeBannerContainerView: UIView!
    @IBOutlet var largeBannerContainerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showParagraphs(stackView: whatStackView, stub: whatStubLabel, paragraphs: what)
        showParagraphs(stackView: whenStackView, stub: whenStubLabel, paragraphs: when)
        showParagraphs(stackView: howStackView, stub: howStubLabel, paragraphs: how)
        
        if let link = link, UIApplication.shared.canOpenURL(link.url) {
            linkButton.setTitle(link.title, for: .normal)
            linkButton.titleLabel?.numberOfLines = 0
            linkButton.isHidden = false
        } else {
            linkButton.isHidden = true
            
            NSLayoutConstraint.activate([
                howStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20.0)
            ])
        }
    }
    
    func loadContent(_ content: SectionedHelpPage) {
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
        
        what = content.what
        when = content.when
        how = content.how
        link = content.link
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
    
    @IBAction func onButtonTapped() {
        guard let link = link, UIApplication.shared.canOpenURL(link.url) else {
            return
        }
        
        UIApplication.shared.open(link.url)
    }
}

extension String {
    fileprivate var data: Data {
        return Data(utf8)
    }
    
    func getFormattedString() -> NSAttributedString? {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let color = Colors.Foreground.primary ?? UIColor.white
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let hex = String(format: "#%02X%02X%02X", Int(round(red * 255)), Int(round(green * 255)), Int(round(blue * 255)))
        let html = "<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: \(font.pointSize); color: \(hex)\">\(self)</span>"
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] =
            [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
             NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue]
        
        return try? NSAttributedString(data: html.data, options: options, documentAttributes: nil)
    }
    
    func getVoiceOverLabel() -> String? {
        let lowercase = self.getFormattedString()?.string.replacingOccurrences(of: "callout", with: "call out")
        return lowercase?.replacingOccurrences(of: "Callout", with: "Call out")
    }
}

extension HelpPageViewController: LargeBannerContainerView {
    
    func setLargeBannerHeight(_ height: CGFloat) {
        largeBannerContainerHeightConstraint.constant = height
    }
    
}
