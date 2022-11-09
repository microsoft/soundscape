//
//  LanguageFormatter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

class LanguageFormatter: NSObject {

    // MARK: Distance & Name Formatter

    private static var defaultOptions: DistanceFormatter.Options {
        return DistanceFormatter.Options(metric: SettingsContext.shared.metricUnits,
                                         rounding: false,
                                         spellOut: false,
                                         locale: LocalizationContext.currentAppLocale,
                                         abbreviated: false)
    }
    
    static func string(from distance: CLLocationDistance,
                       accuracy: Double,
                       name: String) -> String {
        return LanguageFormatter.string(from: distance,
                                        with: name,
                                        accuracy: accuracy)
    }
    
    static func string(from distance: CLLocationDistance,
                       with name: String,
                       rounding: Bool = true,
                       accuracy: CLLocationAccuracy) -> String {
        var options = self.defaultOptions
        options.rounding = rounding
        
        return LanguageFormatter.string(from: distance,
                                        with: name,
                                        accuracy: accuracy,
                                        options: options)
    }
    
    static func string(from distance: CLLocationDistance,
                       with name: String,
                       accuracy: CLLocationAccuracy,
                       options: DistanceFormatter.Options) -> String {
        let formattedDistance = LanguageFormatter.formattedDistance(from: distance, options: options)
        let distanceStyle = DistanceStyle(for: distance, accuracy: accuracy)
        
        return LanguageFormatter.string(fromFormattedDistance: formattedDistance,
                                        distanceStyle: distanceStyle,
                                        name: name)
    }
    
    static func string(fromFormattedDistance formattedDistance: String,
                       distanceStyle: DistanceStyle,
                       name: String) -> String {
        switch distanceStyle {
        case .default:
            return GDLocalizedString("directions.name_distance", name, formattedDistance)
        case .close:
            return GDLocalizedString("directions.name_close_by", name)
        case .about:
            return GDLocalizedString("directions.name_about_distance", name, formattedDistance)
        case .around:
            return GDLocalizedString("directions.name_around_distance", name, formattedDistance)
        }
    }
    
    // MARK: Distance Only Formatter

    static func string(from distance: CLLocationDistance,
                       rounded: Bool = LanguageFormatter.defaultOptions.rounding,
                       spellOut: Bool = LanguageFormatter.defaultOptions.spellOut,
                       abbreviated: Bool = LanguageFormatter.defaultOptions.abbreviated) -> String {
        var options = self.defaultOptions
        options.rounding = rounded
        options.spellOut = spellOut
        options.abbreviated = abbreviated

        return LanguageFormatter.formattedDistance(from: distance, options: options)
    }
    
    static func spellOutDistance(_ distance: CLLocationDistance) -> String {
        return LanguageFormatter.string(from: distance, spellOut: true)
    }
    
    static func formattedDistance(from distance: CLLocationDistance) -> String {
        return LanguageFormatter.formattedDistance(from: distance, options: LanguageFormatter.defaultOptions)
    }
    
    static func formattedDistance(from distance: CLLocationDistance, options: DistanceFormatter.Options) -> String {
        let distanceFormatter = DistanceFormatter(options: options)
        return distanceFormatter.string(fromDistance: distance)
    }
    
}

// MARK: - Relative Directions

extension LanguageFormatter {
    
    static func encodedDirection(toLocation: CLLocation, type: RelativeDirectionType = .combined) -> String {
        return CodeableDirection(destinationCoordinate: toLocation.coordinate, directionType: type).encode()
    }
    
    static func encodedDirection(fromLocation: CLLocation,
                                 toLocation: CLLocation,
                                 heading: CLLocationDirection,
                                 type: RelativeDirectionType = .combined) -> String {
        return CodeableDirection(originCoordinate: fromLocation.coordinate,
                                originHeading: heading,
                                destinationCoordinate: toLocation.coordinate,
                                directionType: type).encode()
    }
    
    static func expandCodedDirection(for string: String) -> String {
        return LanguageFormatter.expandCodedDirection(for: string,
                                                      coordinate: AppContext.shared.geolocationManager.location?.coordinate,
                                                      heading: AppContext.shared.geolocationManager.collectionHeading.value ?? Heading.defaultValue)
    }
    
    static func expandCodedDirection(for string: String, coordinate: CLLocationCoordinate2D?, heading: CLLocationDirection?) -> String {
        let codedDirection: CodeableDirection.Result
        
        do {
            try codedDirection = CodeableDirection.decode(string: string,
                                                          originCoordinate: coordinate,
                                                          originHeading: heading)
        } catch CodeableDirection.DecodingError.invalidOrigin(let result) {
            // The supplied coordinate or heading values are invalid
            codedDirection = result
        } catch {
            return string
        }
        
        let direction =  codedDirection.direction

        // If the relative direction is unknown (heading or bearing could be invalid), use "away" (e.g. "Starbucks is 30 meters away")
        let directionString = direction == .unknown ? GDLocalizedString("directions.direction.away") : direction.localizedString
        
        return string.replacingOccurrences(of: codedDirection.encodedSubstring, with: directionString)
    }
    
}

// MARK: - Distance Style

extension LanguageFormatter {
    
    enum DistanceStyle: String {
        case `default`
        case close
        case about
        case around
        
        private static let closeByDistance = CLLocationDistance(15.0)
        private static let farAwayDistance = CLLocationDistance(200.0)

        private static let goodAccuracy = CLLocationAccuracy(10.0)
        private static let averageAccuracy = CLLocationAccuracy(20.0)

        init(for distance: CLLocationDistance, accuracy: CLLocationAccuracy) {
            let distanceUnit = DistanceUnit.meters(distance)
            let rounded = DistanceFormatter.rounded(distanceUnit: distanceUnit, canChangeUnit: false)
            
            if rounded.doubleValue <= DistanceStyle.closeByDistance {
                self = .close
            } else if distance >= DistanceStyle.farAwayDistance {
                self = .default
            } else {
                if accuracy <= DistanceStyle.goodAccuracy {
                    self = .default
                } else if accuracy <= DistanceStyle.averageAccuracy {
                    self = .about
                } else {
                    self = .around
                }
            }
        }
    }
    
}
