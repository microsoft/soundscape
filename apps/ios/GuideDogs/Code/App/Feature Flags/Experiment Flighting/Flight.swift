//
//  Flight.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

struct Flight: Codable {
    
    /// ETag for the control file downloaded from the experiment service that was parsed into
    /// this `Flight` object. Use this for checking if the Flight configuration needs
    /// to be updated on subsequent launches.
    let etag: String
    
    /// The set of experiment configurations for this flight (groupings of experiments with
    /// probilities for the groups to be active for any given user).
    let configurations: [ExperimentConfiguration]
    
    /// Dictionary containing flags for each experiment configuration indicating whether
    /// that control is active or not.
    private(set) var configStates: [UUID: Bool]
    
    /// The set of experiment descriptions for each experiment
    /// Descriptions will not be available in `release` builds
    var experimentDescriptions: [ExperimentDescription] = []
    
    /// Initializer used when decoding a flight object from a json file saved to disk.
    ///
    /// - Parameter etag: ETag received from downloading the controls.json file
    /// - Parameter configurations: A list of configuration objects controlling which experiments should be on or off
    /// - Parameter configStates: A dictionary containing the UUID of each `ExperimentConfiguration` object and a flag indicating if the experiments in that object are on or off
    init(etag: String, configurations: [ExperimentConfiguration], configStates: [UUID: Bool]) {
        self.etag = etag
        self.configurations = configurations
        self.configStates = configStates
    }
    
    /// Use this initializer when setting up a flight for the first time. This will randomly turn
    /// experiment configurations on or off according to the probability specified in the configuration objects.
    ///
    /// - Parameter etag: ETag received from downloading the controls.json file
    /// - Parameter configurations: A list of configuration objects controlling which experiments should be on or off
    init(etag: String, configurations: [ExperimentConfiguration]) {
        let states = Dictionary(uniqueKeysWithValues: configurations.map { ($0.uuid, Float.random(in: 0.0 ..< 1.0) < $0.probability) })
        self.init(etag: etag, configurations: configurations, configStates: states)
    }
    
    /// - note: Passing the `locale` parameter should only be done when an experiment is to be enabled before the user
    /// has a chance to select a language in the language selection screen on initial lunch.
    /// This option exists in order to be able to compare the device's locale as opposed to the current app locale.
    func isActive(_ experimentID: UUID, locale: Locale = LocalizationContext.currentAppLocale) -> Bool {
        guard let control = configurations.first(where: { $0.experimentIDs.contains(experimentID) }) else {
            return false
        }
        
        guard control.locales.contains(where: { $0.identifierHyphened == locale.identifierHyphened }) else {
            return false
        }
        
        return configStates[control.uuid] ?? false
    }
    
    /// Used to configure the state of an experiment configuration
    ///
    /// - Parameter configId: UUID of the experiment configuration
    /// - Parameter isActive: Sets the state of the configuration
    mutating func setIsActive(configId uuid: UUID, isActive: Bool) {
        guard FeatureFlag.isEnabled(.experimentConfiguration) else {
            return
        }
        
        guard configStates.keys.contains(uuid) else {
            return
        }
        
        configStates[uuid] = isActive
    }
    
}
