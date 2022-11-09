//
//  MPEditAnnotationTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol MPEditAnnotationTableViewCellDelegate: AnyObject {
    func onAnnotationChanged(_ annotation: String)
}

class MPEditAnnotationTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var annotationField: UITextField!
    
    weak var delegate: MPEditAnnotationTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        annotationField.delegate = self
        
        // Creates a custom rightView for the new button and sets the mode for the right view
        annotationField.addCustomClearButton(with: #imageLiteral(resourceName: "clear-14px"), mode: .always)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
    @IBAction func onAnnotationValueChanged(_ sender: Any) {
        if let text = annotationField.text {
            if text == "" {
                annotationField.rightViewMode = .never
            } else {
                annotationField.rightViewMode = .always
            }
            
            delegate?.onAnnotationChanged(text)
        }
    }
}
