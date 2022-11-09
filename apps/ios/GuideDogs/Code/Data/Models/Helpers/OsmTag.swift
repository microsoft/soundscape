//
//  OsmTag.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

import RealmSwift

class OsmTag: Object {
    
    @objc dynamic var key = ""
    
    @objc dynamic var name = ""
    
    @objc dynamic var value = ""
    
    convenience init(name: String, value: String) {
        self.init()
        
        self.name = name
        self.value = value
        
        self.key = name + "=" + value
    }
    
    /// Indicates which property represents the primary key of this object
    ///
    /// - Returns: The name of the property that represents the primary key of this object
    override static func primaryKey() -> String {
        return "key"
    }
}
