//
//  StandbyViewController.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class StandbyViewController: UIViewController {
    
    weak var delegate: DismissableViewControllerDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var snoozeContainer: UIView!
    @IBOutlet weak var wakeContainer: UIView!
    @IBOutlet weak var illustrationImage: UIImageView!
    @IBOutlet var buttonSpacingConstraint: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GDATelemetry.trackScreenView("standby")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AppContext.shared.goToSleep()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onAppOperationStateDidChange), name: Notification.Name.appOperationStateDidChange, object: nil)
        
        view.accessibilityViewIsModal = true
        
        UIView.setGroupAccessibilityElement(for: snoozeContainer,
                                            label: GDLocalizedString("sleep.wake_up_when_i_leave"),
                                            traits: [.button])
        
        UIView.setGroupAccessibilityElement(for: wakeContainer,
                                            label: GDLocalizedString("sleep.wake_up_now"),
                                            traits: [.button])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.appOperationStateDidChange, object: nil)
    }
    
    @objc func onAppOperationStateDidChange() {
        if AppContext.shared.state == .normal {
            dismiss(animated: true) { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.delegate?.onDismissed(self)
            }
        }
    }

    @IBAction func snoozePressed() {
        AppContext.shared.snooze()
        
        snoozeContainer.isHidden = true
        buttonSpacingConstraint.isActive = false
        
        UIView.animate(withDuration: 0.4, animations: {
            self.illustrationImage.image = #imageLiteral(resourceName: "snooze_Illustration")
            self.titleLabel.text = GDLocalizedString("sleep.snoozing")
            self.titleLabel.accessibilityLabel = GDLocalizedString("sleep.snoozing")
            self.messageLabel.text = GDLocalizedString("sleep.snoozing.message")
            self.view.layoutIfNeeded()
        }, completion: { (_) in
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.titleLabel)
        })
    }
    
    @IBAction func wakeUpPressed() {
        AppContext.shared.wakeUp()
    }
    
}
