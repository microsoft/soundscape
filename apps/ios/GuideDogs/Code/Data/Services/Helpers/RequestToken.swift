//
//  RequestToken.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class RequestToken {
    private weak var task: URLSessionDataTask?
    init(task: URLSessionDataTask) {
        self.task = task
    }
    func cancel() {
        task?.cancel()
    }
}
