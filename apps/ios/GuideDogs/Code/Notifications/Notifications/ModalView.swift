//
//  ModalView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

///
/// `RawValue` determines which notification to display if multiple
/// notificaitons can be displayed in the same container
///
enum ModalView: Int, NotificationProtocol {
    case headsetCalibration
    case anyModalView
    
    static var container: NotificationContainer {
        return ModalViewContainer()
    }
    
    var observer: NotificationObserver {
        switch self {
        case .headsetCalibration: return HeadsetCalibrationModalViewObserver()
        case .anyModalView: return AnyModalViewObserver()
        }
    }
}
