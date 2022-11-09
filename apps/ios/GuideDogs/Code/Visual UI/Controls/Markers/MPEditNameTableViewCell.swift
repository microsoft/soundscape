//
//  MPEditNameTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

protocol MPEditNameTableViewCellDelegate: AnyObject {
    func onNameChanged(_ name: String)
    func onEditingDone()
}

class MPEditNameTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    weak var delegate: MPEditNameTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        nameField.delegate = self
        
        // Creates a custom rightView for the new button and sets the mode for the right view
        nameField.addCustomClearButton(with: #imageLiteral(resourceName: "clear-14px"), mode: .always)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.onEditingDone()
        return true
    }

    @IBAction func onNameEditingDidBegin(_ sender: Any) {
        // Ensures that the name is selected when the user starts editing allowing
        // them to either overwrite or append to the name easily.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.nameField.selectAll(nil)
        })
    }
    
    @IBAction func onNameValueChanged(_ sender: Any) {
        if let text = nameField.text {
            if text == "" {
                nameField.rightViewMode = .never
            } else {
                nameField.rightViewMode = .always
            }
            
            delegate?.onNameChanged(text)
        }
    }
}
