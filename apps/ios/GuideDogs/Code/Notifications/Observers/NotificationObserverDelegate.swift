//
//  NotificationObserverDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol NotificationObserverDelegate: AnyObject {
    func stateDidChange(_ observer: NotificationObserver)
    func performSegue(_ observer: NotificationObserver, destination: ViewControllerRepresentable)
    func popToRootViewController(_ observer: NotificationObserver)
}
