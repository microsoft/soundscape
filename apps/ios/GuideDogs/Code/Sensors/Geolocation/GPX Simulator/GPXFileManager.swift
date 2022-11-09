//
//  GPXFileManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CocoaLumberjackSwift

class GPXFileManager {
    
    private static let GPXFileExtension = "gpx"
    
    class var GPXFileDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    /**
     Returns all GPX file URLs from the application documents directory.
     
     - Returns: A list of GPX file URLs
     */
    class func files() -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(string: GPXFileDirectory)!,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [.skipsSubdirectoryDescendants])
            var files: [URL] = []
            for url in fileURLs where url.pathExtension == GPXFileExtension {
                files.append(url)
            }
            
            // Sort by filename
            files.sort(by: { (url1, url2) -> Bool in
                url1.lastPathComponent < url2.lastPathComponent
            })
            
            return files
        } catch let error as NSError {
            DDLogError("Error getting contents of directory: " + error.description)
            return []
        }
    }
    
    /**
     Copies a GPX file from a given location to the GPX files directory.
     
     - Parameter url: The current temporary location of the file
     
     - Returns: True if the operation succeeded, false other otherwise
     */
    class func `import`(url: URL) throws {
        let destination = URL(fileURLWithPath: GPXFileDirectory).appendingPathComponent(url.lastPathComponent)
        try FileManager.default.moveItem(at: url, to: destination)
    }
    
    /**
     Writes a GPX file from a given content and a filename.
     
     - Parameter content: The GPX content as a string
     - Parameter filename: The given GPX file name
     
     - Returns: True if the operation succeeded, false other otherwise
     */
    class func create(content: String, filename: String) -> Bool {
        let filepath = GPXFileDirectory.appending("/" + filename + "." + GPXFileExtension)
        do {
            try content.write(toFile: filepath, atomically: true, encoding: .utf8)
            DDLogDebug("GPX file created at path: " + filepath)
            return true
        } catch let error as NSError {
            DDLogError("Error writing GPX content to file at path: " + filepath + "<" + error.description + ">")
            return false
        }
    }
    
    /**
     Removes a GPX file with a givne file path.
     
     - Parameter filepath: The GPX file path
     
     - Returns: True if the operation succeeded, false other otherwise
     */
    class func remove(filepath: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: filepath)
            DDLogDebug("GPX file deleted at path: " + filepath)
            return true
        } catch let error as NSError {
            DDLogError("Error removing GPX file at path: " + filepath + "<" + error.description + ">")
            return false
        }
    }
    
}
