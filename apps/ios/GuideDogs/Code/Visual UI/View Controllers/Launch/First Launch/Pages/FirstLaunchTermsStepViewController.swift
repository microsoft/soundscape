//
//  FirstLaunchTermsStepViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol FirstLaunchTermsStepDelegate: AnyObject {
    func onTermsAccepted()
}

class FirstLaunchTermsStepViewController: FirstLaunchStepViewController {
    
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var acceptCheckbox: UIImageView!
    @IBOutlet weak var getStartedButton: RoundedSolidButton!
    @IBOutlet weak var getStartedLabel: UILabel!
    @IBOutlet weak var termsOfUseCheckbox: UIButton!
    
    var accepted = false
    
    weak var delegate: FirstLaunchTermsStepDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let hyperlinkText = GDLocalizedString("terms_of_use.service_agreement")
        termsTextView.text = GDLocalizedString("terms_of_use.message", hyperlinkText)
        
        let attributedString = NSMutableAttributedString(attributedString: termsTextView.attributedText)
        let range = (termsTextView.attributedText.string as NSString).range(of: hyperlinkText)
        
        guard range.location != NSNotFound else {
            return
        }
        
        // Add link
        attributedString.addAttribute(NSAttributedString.Key.link,
                                      value: AppContext.Links.servicesAgreementURL(for: LocalizationContext.currentAppLocale),
                                      range: range)
        
        // Underline
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: range)
        
        //
        // Append additional notices
        //
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.preferredFont(forTextStyle: .body)
        ]
        
        let disclaimer = NSAttributedString(string: "\n\n\(GDLocalizedString("terms_of_use.medical_safety_disclaimer"))", attributes: attributes)
        attributedString.append(disclaimer)
        
        let prompt = NSAttributedString(string: "\n\n\(GDLocalizedString("terms_of_use.message.prompt"))", attributes: attributes)
        attributedString.append(prompt)
        
        // Update text and spacing
        termsTextView.attributedText = attributedString
        termsTextView.textContainerInset = UIEdgeInsets(top: 11, left: 8, bottom: 8, right: 8)
        
        // Set the appropriate state for the buttons
        updateButtonViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Automatically have VoiceOver read the full contents of the first launch page
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: header)
    }
    
    @IBAction func acceptCheckboxOnTouchUp(_ sender: UIButton) {
        accepted = !accepted
        
        updateButtonViews()
    }
    
    @IBAction func getStartedOnTouchUp(_ sender: UIButton) {
        delegate?.onTermsAccepted()
    }
    
    func updateButtonViews() {
        termsOfUseCheckbox.accessibilityLabel = GDLocalizedString("terms_of_use.accept_checkbox.acc_label")

        if accepted {
            acceptCheckbox.image = #imageLiteral(resourceName: "ic_check_box_white")
            termsOfUseCheckbox.accessibilityHint = GDLocalizedString("terms_of_use.accept_checkbox.off.acc_hint")
            termsOfUseCheckbox.accessibilityValue = GDLocalizedString("terms_of_use.accept_checkbox.on.acc_value")
            
            getStartedButton.isEnabled = true
            getStartedButton.accessibilityLabel = GDLocalizedString("general.alert.next")
            getStartedButton.accessibilityHint = nil
            getStartedLabel.textColor = .black
        } else {
            acceptCheckbox.image = #imageLiteral(resourceName: "ic_check_box_outline_blank_white")
            termsOfUseCheckbox.accessibilityHint = GDLocalizedString("terms_of_use.accept_checkbox.on.acc_hint")
            termsOfUseCheckbox.accessibilityValue = GDLocalizedString("terms_of_use.accept_checkbox.off.acc_value")
            
            getStartedButton.isEnabled = false
            getStartedButton.accessibilityLabel = GDLocalizedString("general.alert.next")
            getStartedButton.accessibilityHint = GDLocalizedString("first_launch.get_started_button.off.acc_hint")
            getStartedLabel.textColor = .white
        }
    }
}
