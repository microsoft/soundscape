//
//  ActivityIndicatorTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class ActivityIndicatorTableViewCell: UITableViewCell {
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // MARK: View Life Cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        activityIndicatorView.startAnimating()
    }
    
}
