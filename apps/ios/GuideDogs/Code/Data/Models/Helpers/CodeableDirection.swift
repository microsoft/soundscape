//
//  CodeableDirection.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import CocoaLumberjackSwift

/// A formatter that encodes and decodes directions from strings. Format can be on of two options:
/// - `@!destination_lat,destination_lon,direction_type!!`
/// - `@!destination_lat,destination_lon,direction_type,origin_lat,origin_lon,origin_heading!!`
struct CodeableDirection {

    fileprivate struct Delimiter {
        static let start = "@!"
        static let end = "!!"
        static let separator = ","
    }
    
    fileprivate static let regexPattern = Delimiter.start + "[^>]+" + Delimiter.end
    
    typealias Result = (direction: Direction, encodedSubstring: String, range: NSRange)

    enum DecodingError: Error {
        case noDirectionFound
        /// Used when the coded directions does not contain an origin location or heading
        /// and the supplied location or heading are invalid.
        case invalidOrigin(Result)
        case invalidCoordinateOrHeading
        case parsingError(String)
    }
    
    let originCoordinate: CLLocationCoordinate2D?
    let originHeading: CLLocationDirection?
    let destinationCoordinate: CLLocationCoordinate2D
    let directionType: RelativeDirectionType
    
    init(originCoordinate: CLLocationCoordinate2D? = nil,
         originHeading: CLLocationDirection? = nil,
         destinationCoordinate: CLLocationCoordinate2D,
         directionType: RelativeDirectionType = .combined) {
        self.originCoordinate = originCoordinate
        self.originHeading = originHeading
        self.destinationCoordinate = destinationCoordinate
        self.directionType = directionType
    }
    
    init?(string: String) {
        let components = string.components(separatedBy: Delimiter.separator)
        
        guard components.count == 3 || components.count == 6 else {
            DDLogWarn("Invalid relative direction escape sequence")
            return nil
        }
        
        let destinationCoordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(components[0])!,
                                                           longitude: CLLocationDegrees(components[1])!)
        
        guard CodeableDirection.isValid(coordinate: destinationCoordinate) else {
            DDLogWarn("Invalid relative direction latitude/longitude")
            return nil
        }
        
        let originCoordinate: CLLocationCoordinate2D?
        let originHeading: CLLocationDirection?
        
        if components.count == 6 {
            originCoordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(components[3])!,
                                                      longitude: CLLocationDegrees(components[4])!)
            
            guard CodeableDirection.isValid(coordinate: originCoordinate!) else {
                DDLogWarn("Invalid relative direction latitude/longitude")
                return nil
            }
            originHeading = CLLocationDirection(components[5])!
        } else {
            originCoordinate = nil
            originHeading = nil
        }
        
        guard let directionType = RelativeDirectionType(rawValue: Int(components[2])!) else { return nil }
        
        self.originCoordinate = originCoordinate
        self.originHeading = originHeading
        self.destinationCoordinate = destinationCoordinate
        self.directionType = directionType
    }
    
    private static func isValid(coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.isValidLocationCoordinate
    }
    
    func encode() -> String {
        let userInfo: String
        if let originCoordinate = originCoordinate, let originHeading = originHeading {
            userInfo = Delimiter.separator + "\(originCoordinate.latitude)" + Delimiter.separator + "\(originCoordinate.longitude)" + Delimiter.separator + "\(originHeading)"
        } else {
            userInfo = ""
        }
        return Delimiter.start + "\(destinationCoordinate.latitude)" + Delimiter.separator + "\(destinationCoordinate.longitude)" + Delimiter.separator + "\(directionType.rawValue)\(userInfo)" + Delimiter.end
    }
    
    static func decode(string: String,
                       originCoordinate: CLLocationCoordinate2D? = nil,
                       originHeading: CLLocationDirection? = nil) throws -> Result {
        let codedDirection = try string.codedDirectionSubstring()
        
        let direction: Direction
        do {
            direction = try codedDirection.string.decodeDirection(originCoordinate: originCoordinate, originHeading: originHeading)
        } catch CodeableDirection.DecodingError.invalidCoordinateOrHeading {
            let result: Result = (.unknown, codedDirection.string, codedDirection.range)
            throw CodeableDirection.DecodingError.invalidOrigin(result)
        }
 
        return (direction, codedDirection.string, codedDirection.range)
    }
    
}

extension String {
    
    fileprivate func codedDirectionSubstring() throws -> (string: String, range: NSRange) {
        guard !isEmpty else {
            throw CodeableDirection.DecodingError.noDirectionFound
        }
        
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: CodeableDirection.regexPattern, options: [])
        } catch {
            throw CodeableDirection.DecodingError.parsingError("Failed to create regex object")
        }
        
        guard let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) else {
            throw CodeableDirection.DecodingError.noDirectionFound
        }
        
        let substring = self.substring(from: match.range.location, to: match.range.location+match.range.length-1)!
        
        return (substring, match.range)
    }
    
    fileprivate func decodeDirection(originCoordinate: CLLocationCoordinate2D?, originHeading: CLLocationDirection?) throws -> Direction {
        // Remove escaping characters
        let string = self.replacingOccurrences(of: CodeableDirection.Delimiter.start, with: "").replacingOccurrences(of: CodeableDirection.Delimiter.end, with: "")
        
        guard let codeableDirection = CodeableDirection(string: string) else {
            throw CodeableDirection.DecodingError.parsingError("Invalid format for: \(self)")
        }
        
        let originCoordinate = codeableDirection.originCoordinate ?? originCoordinate
        let originHeading = codeableDirection.originHeading ?? originHeading
        
        guard originCoordinate != nil && originHeading != nil else {
            DDLogWarn("Error: Codeable direction in string was not handled. location or heading are not valid.")
            throw CodeableDirection.DecodingError.invalidCoordinateOrHeading
        }
        
        let bearing = originCoordinate!.bearing(to: codeableDirection.destinationCoordinate)
        let direction = Direction(from: originHeading!, to: bearing, type: codeableDirection.directionType)
        
        return direction
    }
    
}
