//
//  AdjacentDataView.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Represents an edge in the rooted graph that Location Previews operate over
protocol AdjacentDataView {
    associatedtype Path: Orientable, Equatable
    associatedtype Adjacent
    associatedtype DecisionPoint: RootedPreviewGraph where DecisionPoint.EdgeData == Self
    
    var endpoint: DecisionPoint.Root { get }
    var direction: Path { get }
    var adjacent: [Adjacent] { get }
    var isSupported: Bool { get }
    
    /// Constructs a `DecisionPoint` (see associated type) for this edge's `endpoint`
    func decisionPointForEndpoint() -> DecisionPoint
    
    /// Generates callouts that should be performed for the items adjacent to
    /// this edge in the rooted graph.
    /// Note: Pass in the valid adjacent objects to be called out. The objects should be part of the
    /// AdjacentDataView `adjacent` property.
    func makeCalloutsForAdjacents() -> [CalloutProtocol]
    
    /// Generates callouts that should be performed when this edge is focussed on by the
    /// user in the Preview experience
    func makeCalloutsForFocusEvent() -> [CalloutProtocol]
    
    /// Generates callouts that should be performed when this edge is focussed on by the
    /// user for an extended period of time in the Preview experience
    func makeCalloutsForLongFocusEvent(from: DecisionPoint.Root) -> [CalloutProtocol]
    
    /// Generates callouts that should be performed when this edge is selected by the
    /// user in the Preview experience
    func makeCalloutsForSelectedEvent(from previousEdgeData: Self) -> [CalloutProtocol]
}
