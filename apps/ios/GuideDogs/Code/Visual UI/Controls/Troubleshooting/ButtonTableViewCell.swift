//
//  ButtonTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class ButtonTableViewCell: UITableViewCell, NibLoadableView {
    
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accessibilityElements = [button as Any]
    }
    
}
