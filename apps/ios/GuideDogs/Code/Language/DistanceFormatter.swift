//
//  DistanceFormatter.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation

/// A formatter that provides localized representations of distance units.
class DistanceFormatter {
    
    // MARK: Types
    
    struct Options {
        static let `default` = Options()
        
        var metric: Bool
        var rounding: Bool
        var spellOut: Bool
        var locale: Locale?
        var abbreviated: Bool
        
        init(metric: Bool = true,
             rounding: Bool = false,
             spellOut: Bool = false,
             locale: Locale? = nil,
             abbreviated: Bool = false) {
            self.metric = metric
            self.rounding = rounding
            self.spellOut = spellOut
            self.locale = locale
            self.abbreviated = abbreviated
        }
    }
    
    // MARK: Static properties
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter
    }()
    
    private static let spellOutNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        formatter.numberStyle = .spellOut
        return formatter
    }()
    
    // MARK: Properties
    
    var options: Options
    
    // MARK: Initialization

    convenience init() {
        self.init(options: .default)
    }
    
    init(options: Options) {
        self.options = options
    }
    
    // MARK: Methods
    
    /// Creates a string representation of the specified distance.
    func string(fromDistance distance: CLLocationDistance) -> String {
        let distanceUnit = DistanceFormatter.formattedDistanceUnit(for: distance,
                                                                   asMetric: options.metric,
                                                                   rounded: options.rounding)

        let number = DistanceFormatter.formattedNumber(distance: distanceUnit.doubleValue,
                                                       spellOut: options.spellOut,
                                                       locale: options.locale)
        
        let unit = distanceUnit.symbol(abbreviated: options.abbreviated)
        
        return GDLocalizedString("distance.format.\(unit)", number)
    }
    
    private static func formattedDistanceUnit(for distance: CLLocationDistance,
                                              asMetric: Bool = true,
                                              rounded: Bool = true) -> DistanceUnit {
        let metricDistanceUnit = DistanceUnit(meters: distance)
        let distanceUnit = asMetric ? metricDistanceUnit : metricDistanceUnit.asImperial
        
        return DistanceFormatter.rounded(distanceUnit: distanceUnit, canChangeUnit: true, roundToNaturalDistance: true)
    }
    
    /// - Note: If `canChangeUnit` is `true`, the returned type could be in a different unit than the one passed in.
    /// For example, if the original unit is `DistanceUnit.meters(99)` and it is rounded to 1000 meters,
    /// the returned unit will be `DistanceUnit.kilometers(1)`.
    static func rounded(distanceUnit: DistanceUnit, canChangeUnit: Bool, roundToNaturalDistance: Bool = false) -> DistanceUnit {
        if roundToNaturalDistance {
            // Metric:
            //  - Distances under 1 km should be rounded to the nearest 5 meters
            //  - Distances over 1 km should be rounded to the nearest 50 meters
            
            // Imperial:
            //  - Distances under 1000 ft should be rounded to the nearest 5 feet
            //  - Distances over 1000 ft should be rounded to the nearest 50 feet
            switch distanceUnit {
            case .meters:
                return distanceUnit.roundToNearestMeters(5, canChangeUnit: canChangeUnit)
            case .kilometers:
                return distanceUnit.roundToNearestMeters(50, canChangeUnit: canChangeUnit)
            case .feet(let feet):
                return distanceUnit.roundToNearestFeet(feet > 1000.0 ? 50 : 5, canChangeUnit: canChangeUnit)
            case .miles:
                return distanceUnit.roundToNearestFeet(50, canChangeUnit: canChangeUnit)
            }
        } else if (distanceUnit.isKilometers || distanceUnit.isMiles) && distanceUnit.doubleValue > 10.0 {
            // Round to the nearest hundredth for distances above 10 kilometers or miles
            // 42.43 miles -> 42.4 miles
            return distanceUnit.roundToDecimalPlaces(1)
        } else {
            // Round to the nearest meter or foot
            // 42.4279 miles -> 42.428 miles
            switch distanceUnit {
            case .meters, .kilometers:
                return distanceUnit.roundToNearestMeters(1, canChangeUnit: canChangeUnit)
            case .feet, .miles:
                return distanceUnit.roundToNearestFeet(1, canChangeUnit: canChangeUnit)
            }
        }
    }
    
    private static func formattedNumber(distance: Double,
                                        spellOut: Bool = false,
                                        locale: Locale? = nil) -> String {
        guard var numberString = DistanceFormatter.numberFormatter.string(from: NSNumber(value: distance)) else {
            return ""
        }
    
        if spellOut, let number = DistanceFormatter.numberFormatter.number(from: numberString) {
            if let locale = locale, DistanceFormatter.spellOutNumberFormatter.locale != locale {
                DistanceFormatter.spellOutNumberFormatter.locale = locale
            }
            
            numberString = DistanceFormatter.spellOutNumberFormatter.string(from: number) ?? ""
        }
        
        return numberString
    }
    
}
