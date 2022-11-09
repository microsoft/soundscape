//
//  ViewControllerRepresentable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/*
 * Implement `ViewControllerRepresentable` and pass instance to a UIKit view
 * that will present the view controller returned by calling `makeViewController`
 *
 * Instances of this class should include all data required to make the given view controller
 */
protocol ViewControllerRepresentable {
    func makeViewController() -> UIViewController?
}
