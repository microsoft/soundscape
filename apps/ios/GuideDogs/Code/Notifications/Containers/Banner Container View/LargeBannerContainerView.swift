//
//  LargeBannerContainerView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol LargeBannerContainerView {
    var largeBannerContainerView: UIView! { get }
    func setLargeBannerHeight(_ height: CGFloat)
}
