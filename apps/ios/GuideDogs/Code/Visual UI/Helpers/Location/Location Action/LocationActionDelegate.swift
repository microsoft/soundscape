//
//  LocationActionDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

protocol LocationActionDelegate: AnyObject {
    func didSelectLocationAction(_ action: LocationAction, detail: LocationDetail)
}
