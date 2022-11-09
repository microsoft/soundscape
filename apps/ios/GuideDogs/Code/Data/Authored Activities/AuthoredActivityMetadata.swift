//
//  AuthoredActivityMetadata.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Data structure for keeping track of the shared content experiences that can be downloaded
struct AuthoredActivityMetadata: Codable, CustomStringConvertible {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case linkVersion
        case etag
        case contentEtags
        case previouslySelected
    }
    
    /// Primary key and identifier for the experience. This ID should be the name
    /// of the GPX file containing the experience's content.
    var id: String = ""
    
    /// The version of the universal link this event was derived from
    var linkVersion: UniversalLinkVersion
    
    /// ETag from the last time the content was downloaded from the server
    var etag: String?
    
    /// Etags for activity content items like audio clips
    var contentEtags: [String: String]
    
    /// Flag indicating if this experience is the currently selected experience (only one instance should
    /// ever have this set to true at a time)
    var selected: Bool = false
    
    /// Flag indicating that this experience was the last one selected
    var previouslySelected: Bool
    
    /// Debug description of the activity
    var description: String {
        return "\(id): \(selected) [Previous: \(previouslySelected), ETag: \(etag ?? "unknown"), URL: \(downloadPath?.absoluteString ?? "error")]"
    }
    
    /// Remote server path that the content can be downloaded from
    var downloadPath: URL? {
        var components = URLComponents()
        
        switch linkVersion {
        case .v1:
            components.scheme = "https"
            components.host = "soundscapeassets.blob.core.windows.net"
            components.path = "/sharedcontent/authoring/\(id).gpx"
            
        case .v2:
            components.scheme = "https"
            components.host = "stauthoringdata.blob.core.windows.net"
            components.path = "/authoring/content/activities/\(id)/activity.gpx"
            
        case .v3:
            components.scheme = "https"
            components.host = "stauthoringdatadev.blob.core.windows.net"
            components.path = "/authoring/content/activities/\(id)/activity.gpx"
        }
        
        return components.url
    }
    
    init(id: String, linkVersion: UniversalLinkVersion, etag: String? = nil, contentEtags: [String: String] = [:], selected: Bool = false) {
        self.id = id
        self.linkVersion = linkVersion
        self.etag = etag
        self.contentEtags = contentEtags
        self.selected = selected
        self.previouslySelected = selected
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        linkVersion = try container.decodeIfPresent(UniversalLinkVersion.self, forKey: .linkVersion) ?? .v1
        etag = try container.decodeIfPresent(String.self, forKey: .etag)
        contentEtags = try container.decodeIfPresent([String: String].self, forKey: .contentEtags) ?? [:]
        previouslySelected = try container.decode(Bool.self, forKey: .previouslySelected)
        
        // When reading from file, selected always starts as false, requiring the select method to be explicitly called
        selected = false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(linkVersion, forKey: .linkVersion)
        
        if let etag = etag {
            try container.encode(etag, forKey: .etag)
        }
        
        try container.encode(contentEtags, forKey: .contentEtags)
        
        // Store the current state of `selected` in `previouslySelected` in the encoded output
        try container.encode(selected, forKey: .previouslySelected)
    }
}
