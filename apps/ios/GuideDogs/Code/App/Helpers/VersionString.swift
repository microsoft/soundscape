//
//  VersionString.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct VersionString: Hashable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let revision: Int
    
    /// Optional build number
    let build: Int?
    
    var string: String {
        guard let build = build else {
            return "\(major).\(minor).\(revision)"
        }

        return "\(major).\(minor).\(revision).\(build)"
    }
    
    init() {
        major = 0
        minor = 0
        revision = 0
        build = nil
    }
    
    init(_ versionString: String?) {
        guard let version = versionString else {
            major = 0
            minor = 0
            revision = 0
            build = nil
            return
        }
        
        let parts = version.split(separator: ".").map { Int($0) ?? 0 }
        
        switch parts.count {
        case 3:
            major = parts[0]
            minor = parts[1]
            revision = parts[2]
            build = nil
            
        case 4:
            major = parts[0]
            minor = parts[1]
            revision = parts[2]
            build = parts[3]
            
        default:
            major = 0
            minor = 0
            revision = 0
            build = nil
            return
        }
    }
    
    // MARK: Comparison Operators
    
    static func == (left: VersionString, right: VersionString) -> Bool {
        return left.major == right.major && left.minor == right.minor && left.revision == right.revision && left.build == right.build
    }
    
    static func != (left: VersionString, right: VersionString) -> Bool {
        return !(left == right)
    }
    
    static func < (left: VersionString, right: VersionString) -> Bool {
        guard left.major == right.major else {
            return left.major < right.major
        }
        
        guard left.minor == right.minor else {
            return left.minor < right.minor
        }
        
        guard left.revision == right.revision else {
            return left.revision < right.revision
        }
        
        // Treat missing build numbers as being 0
        let lBuild = left.build ?? 0
        let rBuild = right.build ?? 0
        
        return lBuild < rBuild
    }
    
    static func > (left: VersionString, right: VersionString) -> Bool {
        return !(left < right) && !(left == right)
    }
    
    static func >= (left: VersionString, right: VersionString) -> Bool {
        return !(left < right)
    }
    
    static func <= (left: VersionString, right: VersionString) -> Bool {
        return left < right || left == right
    }
    
    // MARK: CustomStringConvertible
    
    var description: String {
        return string
    }
}
