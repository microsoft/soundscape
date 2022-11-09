//
//  Recommender.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import Combine
import SwiftUI

protocol Recommender {
    var publisher: CurrentValueSubject<(() -> AnyView)?, Never> { get }
}
