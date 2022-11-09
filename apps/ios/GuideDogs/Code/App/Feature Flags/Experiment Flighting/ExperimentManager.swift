//
//  ExperimentManager.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum KnownExperiment: CaseIterable {
    
    //
    // Supports client experimentation
    // For each experiment, add a case to `KnownExperiment`
    //
    
    var uuid: UUID {
        /*
        switch self {
            case someExperiment: return "Experiment UUID"
        }
         */
        
        // Return a UUID for each known experiment
        return UUID()
    }
    
    static let configurationVersion = "1.0.0"
}

protocol ExperimentManagerDelegate: AnyObject {
    /// Called when the flight manager has finished downloading the experiment controls file
    func onExperimentManagerReady()
}

class ExperimentManager {
    
    weak var delegate: ExperimentManagerDelegate?
    
    private lazy var directory: URL? = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Experiments")
    }()
    
    private lazy var url: URL? = {
        return directory?.appendingPathComponent("controls.json")
    }()
    
    private let queue = DispatchQueue(label: "com.company.appname.flightmanager")
    
    private let service = ExperimentServiceModel()
    
    private(set) var currentFlight: Flight? {
        didSet {
            guard let flight = currentFlight else {
                return
            }
            
            // Save to disk
            saveConfiguration(flight)
        }
    }
    
    init() {
        currentFlight = loadConfiguration()
    }
    
    /// Attempts to download the current experiment control document from the services. If the document can
    /// be downloaded, it is saved and stored to the `currentFlight` object. The `onExperimentManagerReady()`
    /// delegate method will be called when the document is either downloaded or the download times out
    /// or fails.
    func initialize() {
        let shouldDownloadDescriptions = FeatureFlag.isEnabled(.experimentConfiguration)
        
        var configurationDidComplete = false
        var descriptionsDidComplete = shouldDownloadDescriptions ? false : true
        
        service.getExperimentConfiguration(queue: queue, currentEtag: currentFlight?.etag) { [weak self] (result) in
            defer {
                configurationDidComplete = true
                
                if descriptionsDidComplete {
                    self?.delegate?.onExperimentManagerReady()
                }
            }
            
            switch result {
            case .success(let flight):
                self?.currentFlight = flight
                
            case .failure(let error):
                if let err = error as? ExperimentServiceError, err == .notModified {
                    GDLogAppInfo("Flight controls have not changed since last downloaded...")
                } else {
                    GDLogAppError("Error downloading flight controls: \(error.localizedDescription)")
                }
            }
        }
        
        guard shouldDownloadDescriptions else {
            return
        }
        
        service.getExperimentDescriptions(queue: queue) { [weak self] (result) in
            defer {
                descriptionsDidComplete = true
                
                if configurationDidComplete {
                    self?.delegate?.onExperimentManagerReady()
                }
            }
            
            switch result {
            case .success(let descriptions): self?.currentFlight?.experimentDescriptions = descriptions
            case .failure(let error): GDLogAppError("Error downloading flight controls: \(error.localizedDescription)")
            }
        }
    }
    
    /// Checks the current flight to see if there is an experiment control that contains the UUID
    /// for the provided experiment. If there is such an experiment control, then it check if the
    /// experiment is active.
    ///
    /// - Parameter experiment: Experiment to check for
    /// - Parameter locale: Locale to check for
    ///
    /// - note: Passing the `locale` parameter should only be done when an experiment is to be enabled before the user
    /// has a chance to select a language in the language selection screen on initial lunch.
    /// This option exists in order to be able to compare the device's locale as opposed to the current app locale.
    func isEnabled(_ experiment: KnownExperiment, locale: Locale = LocalizationContext.currentAppLocale) -> Bool {
        return currentFlight?.isActive(experiment.uuid, locale: locale) ?? false
    }
    
    /// Used to configure the state of an experiment configuration
    ///
    /// - Parameter configId: UUID of the experiment configuration
    /// - Parameter isEnabled: Sets the state of the configuration
    func setIsEnabled(configId uuid: UUID, isEnabled: Bool) {
        guard FeatureFlag.isEnabled(.experimentConfiguration) else {
            return
        }
        
        self.currentFlight?.setIsActive(configId: uuid, isActive: isEnabled)
    }
    
    /// Loads the current flight configuration document from disk (if one has previously been downloaded)
    private func loadConfiguration() -> Flight? {
        guard let url = url else {
            GDLogAppError("Unable to load current flight state")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Flight.self, from: data)
        } catch {
            GDLogAppError("Unable to save current flight state")
            return  nil
        }
    }
    
    /// Saves a flight configuration to disk
    ///
    /// - Parameter configuration: The flight configuration to save
    private func saveConfiguration(_ configuration: Flight) {
        guard let url = url, let dir = directory else {
            GDLogAppError("Unable to save current flight state")
            return
        }

        do {
            // Check for directories and create them if necessary
            if !FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Save state file
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: url)
        } catch {
            GDLogAppError("Unable to save current flight state")
            return
        }
    }
    
}
