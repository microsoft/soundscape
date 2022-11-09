//
//  ServiceModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class ServiceModel {
    enum StaticHTTPHeader {
        case version
        
        var name: String {
            switch self {
            case .version: return "App-Version"
            }
        }
        
        var value: String {
            switch self {
            case .version: return AppContext.appVersion
            }
        }
    }
    
    /// Maximum amount of time (in seconds) to let a request live before timing it out
    static let requestTimeout = 20.0
    
    /// String for identifying errors that originate from Soundscape services
    static let errorDomain = "GDAHTTPErrorDomain"
    /// String for identifying errors that originate from Realm
    static let errorRealm = "GDAHTTPErrorRealm"
    
    private static let productionServicesHostName = "https://soundscape-production.yourservicesdomain.com"
    private static let productionAssestsHostName = "https://yourstaticblobstore"
    // Do not change `productionVoicesHostName`!
    private static let productionVoicesHostName = "https://yourstaticblobstore"
    
    static var learningResourcesWebpage: URL {
        return URL(string: productionAssestsHostName + "/externalcontent/soundscape_learning_resources.html")!
    }

    static var servicesHostName: String {
        if FeatureFlag.isEnabled(.developerTools), let debugHostName = DebugSettingsContext.shared.servicesHostName, debugHostName.isEmpty == false {
            return debugHostName
        }
        
        return productionServicesHostName
    }
    
    static var assetsHostName: String {
        if FeatureFlag.isEnabled(.developerTools), let debugHostName = DebugSettingsContext.shared.assetsHostName, debugHostName.isEmpty == false {
            return debugHostName
        }
        
        return productionAssestsHostName
    }
    
    static var voicesHostName: String {
        if FeatureFlag.isEnabled(.developerTools), let debugHostName = DebugSettingsContext.shared.assetsHostName, debugHostName.isEmpty == false {
            return debugHostName
        }
        
        return productionVoicesHostName
    }
    
    static func validateResponse(request: URLRequest, response: URLResponse?, data: Data?, error: Error?, callback: @escaping (HTTPStatusCode, Error?) -> Void) -> HTTPStatusCode? {
        // Some more housekeeping
        ServiceModel.logNetworkResponse(response, request: request, error: error)
        
        // Do we have an error?
        guard error == nil else {
            DispatchQueue.main.async {
                callback(.unknown, error!)
            }
            
            return nil
        }
        
        // Is the response of the proper type? (it always should be...)
        guard let httpResponse = response as? HTTPURLResponse else {
            GDLogNetworkError("Response error: response object is not an HTTPURLResponse")
            
            DispatchQueue.main.async {
                callback(.unknown, NSError(domain: ServiceModel.errorDomain, code: NSURLErrorBadServerResponse, userInfo: nil))
            }
            
            return nil
        }
        
        let status = HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .unknown
        
        // Make sure we have a known status
        guard status != .unknown else {
            DispatchQueue.main.async {
                callback(status, NSError(domain: ServiceModel.errorDomain, code: status.rawValue, userInfo: nil))
            }
            
            return nil
        }
        
        // Check the ETag (if the request returned a 304, then there is nothing to do because the data hasn't changed)
        guard status != .notModified else {
            DispatchQueue.main.async {
                callback(status, nil)
            }
            
            return nil
        }
        
        // If we get this far, then the data property should not be nil
        guard data != nil else {
            DispatchQueue.main.async {
                callback(status, nil)
            }
            
            return nil
        }
        
        return status
    }
    
    static func validateJsonResponse(request: URLRequest, response: URLResponse?, data: Data?, error: Error?) -> [String: Any]? {
        guard error == nil else {
            return nil
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        
        guard let status = HTTPStatusCode(rawValue: httpResponse.statusCode), status == .success else {
            return nil
        }
        
        guard let data = data else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        
        return json as? [String: Any]
    }
    
    static func validateJsonResponse(request: URLRequest, response: URLResponse?, data: Data?, error: Error?, callback: @escaping (HTTPStatusCode, Error?) -> Void) -> (HTTPStatusCode, String, [String: Any])? {
        // Some more housekeeping
        ServiceModel.logNetworkResponse(response, request: request, error: error)
        
        // Do we have an error?
        guard error == nil else {
            DispatchQueue.main.async {
                callback(.unknown, error!)
            }
            
            return nil
        }
        
        // Is the response of the proper type? (it always should be...)
        guard let httpResponse = response as? HTTPURLResponse else {
            GDLogNetworkError("Response error: response object is not an HTTPURLResponse")
            
            DispatchQueue.main.async {
                callback(.unknown, NSError(domain: ServiceModel.errorDomain, code: NSURLErrorBadServerResponse, userInfo: nil))
            }
            
            return nil
        }
        
        let newEtag = httpResponse.allHeaderFields[HTTPHeader.eTag.rawValue] as? String ?? NSUUID().uuidString
        let status = HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .unknown
        
        // Make sure we have a known status
        guard status != .unknown else {
            DispatchQueue.main.async {
                callback(status, NSError(domain: ServiceModel.errorDomain, code: status.rawValue, userInfo: nil))
            }
            
            return nil
        }
        
        // Check the ETag (if the request returned a 304, then there is nothing to do because the data hasn't changed)
        guard status != .notModified else {
            DispatchQueue.main.async {
                callback(status, nil)
            }
            
            return nil
        }
        
        // If we get this far, then the data property should not be nil, and it should be valid JSON
        guard let data = data, let parsed = try? JSONSerialization.jsonObject(with: data), let json = parsed as? [String: Any] else {
            DispatchQueue.main.async {
                callback(status, ServiceError.jsonParseFailed)
            }
            
            return nil
        }
        
        return (status, newEtag, json)
    }
    
    static func logNetworkRequest(_ request: URLRequest) {
        guard let httpMethod = request.httpMethod else {
            return
        }
        
        let method = httpMethod.count > 2 ? httpMethod.substring(to: 3)! : httpMethod
        
        GDLogNetworkVerbose("Request (\(method)) \(request.url?.absoluteString ?? "unknown")")
    }
    
    static func logNetworkResponse(_ response: URLResponse?, request: URLRequest, error: Error?) {
        guard let response = response else {
            GDLogNetworkError("Response error: response object is nil")
            return
        }
        
        let responseStatus: HTTPStatusCode
        
        if let res = response as? HTTPURLResponse {
            responseStatus = HTTPStatusCode(rawValue: res.statusCode) ?? .unknown
        } else {
            responseStatus = .unknown
        }
        
        guard let httpMethod = request.httpMethod else {
            return
        }
        
        let method = httpMethod.count > 2 ? httpMethod.substring(to: 3)! : httpMethod
        
        if error != nil {
            GDLogNetworkError("Response error (\(method)) \(responseStatus.rawValue) '\(request.url?.absoluteString ?? "unknown")': \(error.debugDescription)")
        } else {
            GDLogNetworkVerbose("Response (\(method)) \(responseStatus.rawValue) '\(request.url?.absoluteString ?? "unknown")'")
        }
    }
}

extension URLRequest {
    mutating func setAppVersionHeader() {
        self.setValue(ServiceModel.StaticHTTPHeader.version.value, forHTTPHeaderField: ServiceModel.StaticHTTPHeader.version.name)
    }
    
    mutating func setETagHeader(_ etag: String?) {
        guard let etag = etag else {
            return
        }
        
        self.setValue(etag, forHTTPHeaderField: HTTPHeader.ifNoneMatch.rawValue)
    }
}
