//
//  NotificationProtocol.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// `NotificationProtocol` is used to create a prioritized list of notifications that belong to the given container, where the `RawValue` reflects
/// the prioritized order of the notifications. Meaning, a notification with a `RawValue` of 0 will be displayed before a notification with a `RawValue` of 1, provided
/// that both notifications belong to the same container.
/// Additionally, each notification defines an `observer` which is responsible for providing the appropriate
/// view controller that is used to present the notification.
///
protocol NotificationProtocol: Comparable, CaseIterable, RawRepresentable where Self.RawValue == Int {
    static var container: NotificationContainer { get }
    var observer: NotificationObserver { get }
}

extension NotificationProtocol {
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
}
