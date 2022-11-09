//
//  BannerViewControllerDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol BannerViewControllerDelegate: AnyObject {
    func didSelect(_ bannerViewController: BannerViewController)
    func didDismiss(_ bannerViewController: BannerViewController)
}
