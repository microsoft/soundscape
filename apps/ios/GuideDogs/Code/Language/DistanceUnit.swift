//
//  DistanceUnit.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// An enumeration type for the various distance units.
enum DistanceUnit {
    case meters(Double)
    case kilometers(Double)
    case feet(Double)
    case miles(Double)
}

// MARK: - Constants

extension DistanceUnit {
    static let oneMeter = DistanceUnit.meters(1.0)
    static let oneKilometer = DistanceUnit.kilometers(1.0)
    static let oneFoot = DistanceUnit.feet(1.0)
    static let oneMile = DistanceUnit.miles(1.0)
    static let oneThousandFeet = DistanceUnit.feet(1000.0)
}

// MARK: - Initialization

extension DistanceUnit {
    
    /// If `meters` is less than 1km, the type would be `.meters`.
    /// If `meters` is equal or greater than 1km, the type would be `.kilometers`.
    /// Because expressing small fractional numbers in miles is easier for users to
    /// understand than large whole numbers in feet.
    init(meters: Double) {
        if meters < DistanceUnit.oneKilometer.asMeters.doubleValue {
            self = .meters(meters)
        } else {
            self = .kilometers(meters.metersToKilometers)
        }
    }
    
    /// If `feet` is less than 1000ft, the type would be `.feet`.
    /// If `feet` is equal or greater than 1000ft, the type would be `.miles`.
    init(feet: Double) {
        if feet < DistanceUnit.oneThousandFeet.doubleValue {
            self = .feet(feet)
        } else {
            self = .miles(feet.feetToMiles)
        }
    }
    
}

// MARK: - Distance Unit Symbol

extension DistanceUnit {
    
    func symbol(abbreviated: Bool = false) -> String {
        switch self {
        case .meters(let meters):
            return abbreviated ? "m" : (meters.roundToDecimalPlaces(2) == DistanceUnit.oneMeter.doubleValue) ? "meter" : "meters"
        case .kilometers(let kilometers):
            return abbreviated ? "km" : (kilometers.roundToDecimalPlaces(2) == DistanceUnit.oneKilometer.doubleValue) ? "kilometer" : "kilometers"
        case .feet(let feet):
            return abbreviated ? "ft" : (feet.roundToDecimalPlaces(2) == DistanceUnit.oneFoot.doubleValue) ? "foot" : "feet"
        case .miles(let miles):
            return abbreviated ? "mi" : (miles.roundToDecimalPlaces(2) == DistanceUnit.oneMile.doubleValue) ? "mile" : "miles"
        }
    }
    
}

// MARK: - Distance Unit Type

extension DistanceUnit {
    
    var isMeters: Bool {
        switch self {
        case .meters: return true
        default: return false
        }
    }
    
    var isKilometers: Bool {
        switch self {
        case .kilometers: return true
        default: return false
        }
    }
    
    var isFeet: Bool {
        switch self {
        case .feet: return true
        default: return false
        }
    }
    
    var isMiles: Bool {
        switch self {
        case .miles: return true
        default: return false
        }
    }
    
    var isMetric: Bool {
        switch self {
        case .meters, .kilometers: return true
        default: return false
        }
    }
    
}

// MARK: - Enum Conversions

extension DistanceUnit {
    
    var asMetric: DistanceUnit {
        switch self {
        case .meters, .kilometers: return self
        case .feet, .miles: return DistanceUnit(meters: self.asMeters.doubleValue)
        }
    }
    
    var asImperial: DistanceUnit {
        switch self {
        case .meters, .kilometers: return DistanceUnit(feet: self.asFeet.doubleValue)
        case .feet, .miles: return self
        }
    }
    
    var asMeters: DistanceUnit {
        switch self {
        case .meters: return self
        case .kilometers(let kilometers): return .meters(kilometers.kilometersToMeters)
        case .feet(let feet): return .meters(feet.feetToMeters)
        case .miles(let miles): return .meters(miles.milesToMeters)
        }
    }
    
    var asKilometers: DistanceUnit {
        switch self {
        case .meters(let meters): return .kilometers(meters.metersToKilometers)
        case .kilometers: return self
        case .feet(let feet): return .kilometers(feet.feetToKilometers)
        case .miles(let miles): return .kilometers(miles.milesToKilometers)
        }
    }
    
    var asFeet: DistanceUnit {
        switch self {
        case .meters(let meters): return .feet(meters.metersToFeet)
        case .kilometers(let kilometers): return .feet(kilometers.kilometersToFeet)
        case .feet: return self
        case .miles(let miles): return .feet(miles.milesToFeet)
        }
    }
    
    var asMiles: DistanceUnit {
        switch self {
        case .meters(let meters): return .miles(meters.metersToMiles)
        case .kilometers(let kilometers): return .miles(kilometers.kilometersToMiles)
        case .feet(let feet): return .miles(feet.feetToMiles)
        case .miles: return self
        }
    }
    
    var doubleValue: Double {
        switch self {
        case .meters(let meters): return meters
        case .kilometers(let kilometers): return kilometers
        case .feet(let feet): return feet
        case .miles(let miles): return miles
        }
    }
    
}

// MARK: - Rounding

extension DistanceUnit {
    
    /// - Note: If `canChangeUnit` is `true`, the returned type could be in a different unit than the current one.
    /// For example, if the current unit is `DistanceUnit.meters(99)` and it is rounded to 1000 meters,
    /// the returned unit will be `DistanceUnit.kilometers(1)`.
    func roundToNearestMeters(_ nearestMeters: Double, canChangeUnit: Bool = false) -> DistanceUnit {
        let roundedMeters = asMeters.doubleValue.roundToNearest(nearestMeters)
        let roundedUnit = DistanceUnit.meters(roundedMeters)

        switch self {
        case .meters:
            return canChangeUnit ? DistanceUnit(meters: roundedMeters) : roundedUnit
        case .kilometers:
            return canChangeUnit ? DistanceUnit(meters: roundedMeters) : roundedUnit.asKilometers
        case .feet:
            return canChangeUnit ? DistanceUnit(feet: roundedUnit.asFeet.doubleValue) : roundedUnit.asFeet
        case .miles:
            return canChangeUnit ? DistanceUnit(feet: roundedUnit.asFeet.doubleValue) : roundedUnit.asMiles
        }
    }
    
    /// - Note: If `canChangeUnit` is `true`, the returned type could be in a different unit than the current one.
    /// For example, if the current unit is `DistanceUnit.feet(99)` and it is rounded to 1000 feet,
    /// the returned unit will be `DistanceUnit.miles(0.189394)`.
    func roundToNearestFeet(_ nearestFeet: Double, canChangeUnit: Bool = false) -> DistanceUnit {
        let roundedFeet = asFeet.doubleValue.roundToNearest(nearestFeet)
        let roundedUnit = DistanceUnit.feet(roundedFeet)
        
        switch self {
        case .meters:
            return canChangeUnit ? DistanceUnit(meters: roundedUnit.asMeters.doubleValue) : roundedUnit.asMeters
        case .kilometers:
            return canChangeUnit ? DistanceUnit(meters: roundedUnit.asMeters.doubleValue) : roundedUnit.asKilometers
        case .feet:
            return canChangeUnit ? DistanceUnit(feet: roundedFeet) : roundedUnit
        case .miles:
            return canChangeUnit ? DistanceUnit(feet: roundedFeet) : roundedUnit.asMiles
        }
    }
    
    func roundToDecimalPlaces(_ toDecimalPlaces: Int) -> DistanceUnit {
        switch self {
        case .meters(let meters):
            return .meters(meters.roundToDecimalPlaces(toDecimalPlaces))
        case .kilometers(let kilometers):
            return .kilometers(kilometers.roundToDecimalPlaces(toDecimalPlaces))
        case .feet(let feet):
            return .feet(feet.roundToDecimalPlaces(toDecimalPlaces))
        case .miles(let miles):
            return .miles(miles.roundToDecimalPlaces(toDecimalPlaces))
        }
    }
}

extension Double {
    
    internal func roundToNearest(_ toNearest: Double) -> Double {
        return (self / toNearest).rounded() * toNearest
    }
    
    internal func roundToDecimalPlaces(_ toDecimalPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(toDecimalPlaces))
        return (self * divisor).rounded() / divisor
    }
    
}

extension Float {
    internal func roundToNearest(_ toNearest: Float) -> Float {
        return (self / toNearest).rounded() * toNearest
    }
    
    internal func roundToDecimalPlaces(_ toDecimalPlaces: Int) -> Float {
        let divisor = pow(10.0, Float(toDecimalPlaces))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Distance Conversions

extension Double {
    
    // MARK: Meters
    
    fileprivate var metersToKilometers: Double {
        return convert(from: UnitLength.meters, to: UnitLength.kilometers)
    }
    
    fileprivate var metersToFeet: Double {
        return convert(from: UnitLength.meters, to: UnitLength.feet)
    }
    
    fileprivate var metersToMiles: Double {
        return convert(from: UnitLength.meters, to: UnitLength.miles)
    }
    
    // MARK: Kilometers
    
    fileprivate var kilometersToMeters: Double {
        return convert(from: UnitLength.kilometers, to: UnitLength.meters)
    }
    
    fileprivate var kilometersToFeet: Double {
        return convert(from: UnitLength.kilometers, to: UnitLength.feet)
    }
    
    fileprivate var kilometersToMiles: Double {
        return convert(from: UnitLength.kilometers, to: UnitLength.miles)
    }
    
    // MARK: Feet

    fileprivate var feetToMiles: Double {
        return convert(from: UnitLength.feet, to: UnitLength.miles)
    }
    
    fileprivate var feetToMeters: Double {
        return convert(from: UnitLength.feet, to: UnitLength.meters)
    }
    
    fileprivate var feetToKilometers: Double {
        return convert(from: UnitLength.feet, to: UnitLength.kilometers)
    }
    
    // MARK: Miles
    
    fileprivate var milesToFeet: Double {
        return convert(from: UnitLength.miles, to: UnitLength.feet)
    }
    
    fileprivate var milesToMeters: Double {
        return convert(from: UnitLength.miles, to: UnitLength.meters)
    }
    
    fileprivate var milesToKilometers: Double {
        return convert(from: UnitLength.miles, to: UnitLength.kilometers)
    }
    
    // MARK: Generic Conversion

    private func convert(from: UnitLength, to: UnitLength) -> Double {
        return Measurement(value: self, unit: from).converted(to: to).value
    }
    
}
