//
//  NotificationServerDelegate.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol NotificationServerDelegate: AnyObject {
    func stateDidChange<T: NotificationProtocol>(_ server: NotificationServer<T>)
    func performSegue<T: NotificationProtocol>(_ server: NotificationServer<T>, destination: ViewControllerRepresentable)
    func popToRootViewController<T: NotificationProtocol>(_ server: NotificationServer<T>)
}
