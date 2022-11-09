//
//  Thread+Extensions.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

extension Thread {
    var threadName: String {
        if let currentOperationQueue = OperationQueue.current?.name {
            return "<OperationQueue: \(currentOperationQueue)>"
        } else if let underlyingDispatchQueue = OperationQueue.current?.underlyingQueue?.label {
            return "<DispatchQueue: \(underlyingDispatchQueue)>"
        } else {
            let name = __dispatch_queue_get_label(nil)
            return String(cString: name, encoding: .utf8) ?? Thread.current.description
        }
    }
}
