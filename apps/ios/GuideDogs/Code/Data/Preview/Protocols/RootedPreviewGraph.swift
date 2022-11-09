//
//  RootedPreviewGraph.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// A rooted graph data structure representing a point at which a user can make a decision
/// about where to move next in a location preview.
protocol RootedPreviewGraph {
    associatedtype Root: Equatable, Locatable, Localizable
    associatedtype EdgeData: AdjacentDataView where EdgeData.DecisionPoint == Self
    
    var node: Root { get }
    var edges: [EdgeData] { get }
    
    init(node: Root)
    
    /// Generates callouts for the general case when a user arrives at this location in the
    /// preview experience. Use `makeInitialCallouts()` instead if this is the user's starting
    /// location in the preview experience.
    func makeCallouts(previous: Self) -> [CalloutProtocol]
    
    /// Generates callouts for when the user arrives at this location as their starting location
    /// in the preview experience.
    func makeInitialCallouts(resumed: Bool) -> [CalloutProtocol]
    
    /// Re-generates the current decision point and edge data
    func refreshed() -> Self
}
