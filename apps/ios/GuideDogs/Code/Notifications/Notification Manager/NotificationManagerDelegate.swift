//
//  NotificationManagerDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol NotificationManagerDelegate: AnyObject {
    func stateDidChange(_ manager: NotificationManager)
    func performSegue(_ manager: NotificationManager, destination: ViewControllerRepresentable)
    func popToRootViewController(_ manager: NotificationManager)
}
