//
//  CustomDisclosureTableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class CustomDisclosureTableViewCell: UITableViewCell {
    
    private static let disclosureImage = UIImage(named: "chevron_right-white-18dp")!
    
    private var disclosureImage: TintedImageView {
        let chevronImageView = TintedImageView(image: CustomDisclosureTableViewCell.disclosureImage)
        chevronImageView.normalTintColor = Colors.Foreground.primary
        chevronImageView.highlightedTintColor = Colors.Background.primary
        return chevronImageView
    }
    
    private var activityIndicator: UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = Colors.Foreground.primary
        spinner.startAnimating()
        return spinner
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        self.accessoryView = disclosureImage
        
        self.selectionStyle = .default
    }
    
    func showActivityIndicator() {
        accessoryView = activityIndicator
    }
    
    func hideActivityIndicator() {
        accessoryView = disclosureImage
    }
}
