//
//  Fetchable.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol Fetchable {
    func shouldFetch() -> Bool
    func fetch()
    func fetchAsync(on queue: DispatchQueue, _ completion: @escaping () -> Void)
}
