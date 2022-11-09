//
//  NetworkClient.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

enum NetworkError: Error {
    case noDataReturned
}

struct NetworkResponse {
    var allHeaderFields: [AnyHashable: Any]
    var statusCode: HTTPStatusCode
    
    static var empty: NetworkResponse {
        return .init(allHeaderFields: [:], statusCode: .unknown)
    }
}

protocol NetworkClient {
    func requestData(_ request: URLRequest) async throws -> (Data, NetworkResponse)
}

extension URLSession: NetworkClient {
    func requestData(_ request: URLRequest) async throws -> (Data, NetworkResponse) {
        request.log()
        
        if #available(iOS 15.0, *) {
            let (data, response) = try await data(for: request)
            response.log(request: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (data, NetworkResponse(allHeaderFields: [:], statusCode: .unknown))
            }
            
            guard let status = HTTPStatusCode(rawValue: httpResponse.statusCode) else {
                return (data, NetworkResponse(allHeaderFields: httpResponse.allHeaderFields, statusCode: .unknown))
            }
            
            let netResponse = NetworkResponse(allHeaderFields: httpResponse.allHeaderFields, statusCode: status)
            return (data, netResponse)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task: URLSessionDataTask = dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        continuation.resume(with: .failure(error))
                        return
                    }
                    
                    guard let data = data else {
                        continuation.resume(with: .failure(NetworkError.noDataReturned))
                        return
                    }
                    
                    response?.log(request: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, let status = HTTPStatusCode(rawValue: httpResponse.statusCode) else {
                        continuation.resume(with: .success((data, .empty)))
                        return
                    }
                    
                    let response = NetworkResponse(allHeaderFields: httpResponse.allHeaderFields, statusCode: status)
                    continuation.resume(with: .success((data, response)))
                }
                
                task.resume()
            }
        }
    }
}

extension URLRequest {
    func log() {
        guard let method = httpMethod?.prefix(3) else {
            return
        }
        
        GDLogVerbose(.network, "Request (\(method)) \(url?.absoluteString ?? "unknown")")
    }
}

extension URLResponse {
    func log(request: URLRequest) {
        let responseStatus: HTTPStatusCode
        if let res = self as? HTTPURLResponse {
            responseStatus = HTTPStatusCode(rawValue: res.statusCode) ?? .unknown
        } else {
            responseStatus = .unknown
        }
        
        guard let method = request.httpMethod?.prefix(3) else {
            return
        }
        
        GDLogVerbose(.network, "Response (\(method)) \(responseStatus.rawValue) '\(request.url?.absoluteString ?? "unknown")'")
    }
}
