//
//  IntersectionRoadId.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import RealmSwift

/// This class is simply a String wrapper that allows us to have an array of strings
/// stored in Realm with the Intersection object
class IntersectionRoadId: Object {
    @objc dynamic var id: String = ""
    
    convenience init(withId id: String) {
        self.init()
        
        self.id = id
    }
    
    /// Indicates which property represents the primary key of this object
    ///
    /// - Returns: The name of the property that represents the primary key of this object
    override static func primaryKey() -> String {
        return "id"
    }
}
