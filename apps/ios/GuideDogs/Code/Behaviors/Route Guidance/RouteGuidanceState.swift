//
//  RouteGuidanceState.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum RouteGuidanceStateError: Error {
    case noDocumentsDirectory
}

struct RouteGuidanceState: Codable, CustomStringConvertible {
    var contentId: String
    
    /// A running counter of the ammount of time a user has spent in the event route
    var totalTime: TimeInterval = 0.0
    
    /// Indicates if the totalTime property is the final time (e.g. the user has completed the event route and
    /// the totalTime should no longer be increased)
    var isFinal: Bool = false
    
    /// The index of the current waypoint the user has set
    var waypointIndex: Int?
    
    /// Indexes of waypoints that have been visited by the user
    var visited: [Int] = []
    
    var description: String {
        var desc = "State: (Shared Content Experience \(contentId))\n"
        
        desc.append("\n\tTotal Time: \(totalTime)\n")
        desc.append("\tWaypoint Index: \(waypointIndex ?? -1)\n")
        desc.append("\tVisited Indices: \(visited)\n")
        
        return desc
    }
    
    init(id: String) {
        contentId = id
    }
}

extension RouteGuidanceState {
    
    /// Save's the state to a file in the user's documents directory (in the subdirectory
    /// `SharedExperiences/State/`).
    ///
    /// - Parameter id: ID of the shared content experience this state cooresponds to
    /// - Throws: Throws if the data cannot be encoded
    func save(id: String) throws {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw RouteGuidanceStateError.noDocumentsDirectory
        }
        
        let stateDir = documents.appendingPathComponent("SharedExperiences").appendingPathComponent("State")
        let url = stateDir.appendingPathComponent("\(id).json")
        
        // Check for directories and create them if necessary
        if !FileManager.default.fileExists(atPath: stateDir.path) {
            try FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Save state file
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }
    
    /// Loads behavior state for the experience ID provided.
    ///
    /// - Parameter id: ID of the shared content experience this state cooresponds to
    /// - Returns: The loaded state for the shared content experience if it exists or nil otherwise
    static func load(id: String) -> RouteGuidanceState? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = dir.appendingPathComponent("SharedExperiences").appendingPathComponent("State").appendingPathComponent("\(id).json")
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RouteGuidanceState.self, from: data)
        } catch {
            return nil
        }
    }
}
