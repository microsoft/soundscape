//
//  POITableViewCell.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import UIKit

class POITableViewCell: UITableViewCell, NibLoadableView {
    
    enum ImageViewType {
        case marker
        case place
        case search
        case new
        case none
    }
    
    // MARK: `IBOutlet`
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet private weak var markerImageView: UIImageView!
    @IBOutlet private weak var searchImageView: UIImageView!
    @IBOutlet private weak var placeImageView: UIImageView!
    // The image used as a "new badge" is smaller than the
    // other image view. It is wrapped in a `UIView` to ensure
    // equal spacing to the other image views
    @IBOutlet private weak var newImageView: UIView!
    
    // MARK: Properties
    
    var imageViewType: ImageViewType = .none {
        didSet {
            switch imageViewType {
            case .marker:
                markerImageView.isHidden = false
                searchImageView.isHidden = true
                placeImageView.isHidden = true
                newImageView.isHidden = true
            case .place:
                markerImageView.isHidden = true
                searchImageView.isHidden = true
                placeImageView.isHidden = false
                newImageView.isHidden = true
            case .search:
                markerImageView.isHidden = true
                searchImageView.isHidden = false
                placeImageView.isHidden = true
                newImageView.isHidden = true
            case .new:
                markerImageView.isHidden = true
                searchImageView.isHidden = true
                placeImageView.isHidden = true
                newImageView.isHidden = false
            case .none:
                markerImageView.isHidden = true
                searchImageView.isHidden = true
                placeImageView.isHidden = true
                newImageView.isHidden = true
            }
        }
    }
    
}
