//
//  ExperimentServiceModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

/// Error type for the experiment service model
enum ExperimentServiceError: Error {
    case notModified
    case badResponse
    case badStatus
    case badJSON
}

class ExperimentServiceModel {
    
    private static var controlsPath = "/flights/controls_v\(KnownExperiment.configurationVersion).json"
    private static let experimentsPath = "/flights/experiments_v\(KnownExperiment.configurationVersion).json"
    
    /// Timeout for downloading the controls file (this is a quick timeout since this download occurs
    /// during initial launch and therefore needs to be fast)
    private static let requestTimeout: TimeInterval = 5.0
    
    /// Downloads the current control file from the experiments service using the provided dispatch queue.
    /// If an ETag is provided and the service indicates the file hasn't changed, the completion callback
    /// will be called with an error result of `ExperimentServiceError.notModified`.
    ///
    /// - Parameter queue: Dispatch queue to download the control file on
    /// - Parameter currentEtag: ETag from the previous time the file was downloaded
    /// - Parameter completion: Completion callback
    func getExperimentConfiguration(queue: DispatchQueue, currentEtag: String? = nil, completion: @escaping (Result<Flight, Error>) -> Void) {
        let url = URL(string: "\(ServiceModel.assetsHostName)\(ExperimentServiceModel.controlsPath)")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: ExperimentServiceModel.requestTimeout)
                
        // Some housekeeping: Show the network activity indicator on the status bar, set headers, and log the request
        request.setETagHeader(currentEtag)
        request.setAppVersionHeader()
        ServiceModel.logNetworkRequest(request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Some more housekeeping
            ServiceModel.logNetworkResponse(response, request: request, error: error)
            
            // Do we have an error?
            if let err = error {
                completion(.failure(err))
                return
            }
            
            // Is the response of the proper type? (it always should be...)
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(ExperimentServiceError.badResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    // Parse the JSON and send it back
                    let configurations = try JSONDecoder().decode([ExperimentConfiguration].self, from: data)
                    let newEtag = httpResponse.allHeaderFields[HTTPHeader.eTag.rawValue] as? String ?? UUID().uuidString
                    completion(.success(Flight(etag: newEtag, configurations: configurations)))
                } catch {
                    completion(.failure(ExperimentServiceError.badJSON))
                }
                
            case 304:
                // Check the ETag (if the request returned a 304, then there is nothing to do because the data hasn't changed)
                completion(.failure(ExperimentServiceError.notModified))
                return
                
            default:
                // We have a bad status
                completion(.failure(ExperimentServiceError.badStatus))
                return
            }
        }
        
        task.resume()
    }
    
    /// Downloads the current control file from the experiments service using the provided dispatch queue.
    ///
    /// - Parameter queue: Dispatch queue to download the control file on
    /// - Parameter completion: Completion callback
    func getExperimentDescriptions(queue: DispatchQueue, completion: @escaping (Result<[ExperimentDescription], Error>) -> Void) {
        let url = URL(string: "\(ServiceModel.assetsHostName)\(ExperimentServiceModel.experimentsPath)")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: ExperimentServiceModel.requestTimeout)
                
        // Some housekeeping: Show the network activity indicator on the status bar, set headers, and log the request
        request.setAppVersionHeader()
        ServiceModel.logNetworkRequest(request)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Some more housekeeping
            ServiceModel.logNetworkResponse(response, request: request, error: error)
            
            // Do we have an error?
            if let err = error {
                completion(.failure(err))
                return
            }
            
            // Is the response of the proper type? (it always should be...)
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(ExperimentServiceError.badResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    // Parse the JSON and send it back
                    let configurations = try JSONDecoder().decode([ExperimentDescription].self, from: data)
                    completion(.success(configurations))
                } catch {
                    completion(.failure(ExperimentServiceError.badJSON))
                }
                
            default:
                // We have a bad status
                completion(.failure(ExperimentServiceError.badStatus))
                return
            }
        }
        
        task.resume()
    }
    
}
