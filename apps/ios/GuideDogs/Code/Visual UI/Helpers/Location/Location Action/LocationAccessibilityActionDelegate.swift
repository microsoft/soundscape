//
//  LocationAccessibilityActionDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol LocationAccessibilityActionDelegate: AnyObject {
    func didSelectLocationAction(_ action: LocationAction, entity: POI)
}
