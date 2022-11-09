//
//  DecisionPoint.swift
//  Soundscape
//
//  Copyright © 2020 Microsoft. All rights reserved.
//

import Foundation

/// A rooted graph data structure representing a point at which a user can make a decision
/// about where to move next in a location preview.
protocol RootedPreviewGraph {
    associatedtype Root: Equatable
    associatedtype Edge: AdjacentDataView where Edge.Node == Root
    
    var node: Root { get }
    var edges: [Edge] { get }
    
    init?(node: Root)
    
    func makeCalloutsForRoot() -> [CalloutProtocol]
}
