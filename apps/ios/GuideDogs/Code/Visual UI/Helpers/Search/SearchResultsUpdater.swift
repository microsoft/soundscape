//
//  SearchResultsUpdater.swift
//  Openscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import CoreLocation
import MapKit

protocol SearchResultsUpdaterDelegate: AnyObject {
    func searchResultsDidStartUpdating()
    func searchResultsDidUpdate(_ searchResults: [POI], searchLocation: CLLocation?)
    func searchResultsDidUpdate(_ searchForMore: String?)
    func searchWasCancelled()
    var isPresentingDefaultResults: Bool { get }
    var telemetryContext: String { get }
    // Set `isCachingRequired = true` if a selected search result will
    // be cached on device
    // Search results can only be cached when an unencumbered coordinate is available
    var isCachingRequired: Bool { get }
}

class SearchResultsUpdater: NSObject {
    
    enum Context {
        case partialSearchText
        case completeSearchText
    }
    
    // MARK: Properties
    
    weak var delegate: SearchResultsUpdaterDelegate?
    private var searchRequestToken: RequestToken?
    private var searchResultsUpdating = false
    private(set) var searchBarButtonClicked = false
    private var location: CLLocation?
    var context: Context = .partialSearchText
    
    // MARK: Initialization
    
    override init() {
        super.init()
        
        // Save user's current location
        location = AppContext.shared.geolocationManager.location
        
        // Observe changes in user's location
        // This is required so that we can present all search
        // results with an accurate distance
        NotificationCenter.default.addObserver(self, selector: #selector(self.onLocationUpdated(_:)), name: Notification.Name.locationUpdated, object: nil)
    }
    
    deinit {
        searchRequestToken?.cancel()
    }
    
    // MARK: Notifications
    
    @objc
    private func onLocationUpdated(_ notification: Notification) {
        guard let location = notification.userInfo?[SpatialDataContext.Keys.location] as? CLLocation else {
            return
        }
        
        self.location = location
    }
    
    // MARK: Selecting Search Results
    
    func selectSearchResult(_ poi: POI, completion: @escaping (SearchResult?, SearchResultError?) -> Void) {
        if let delegate = delegate, delegate.isPresentingDefaultResults {
            GDATelemetry.track("recent_entity_selected.search", with: ["context": delegate.telemetryContext])
            completion(.entity(poi), nil)
        } else {
            completion(.entity(poi), nil)
        }
    }
    
}

// MARK: - UISearchResultsUpdating

extension SearchResultsUpdater: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        searchBarButtonClicked = false
        
        if let searchBarText = searchController.searchBar.text, searchBarText.isEmpty == false {
            // Fetch new search results
            switch context {
            case .partialSearchText: partialSearchWithText(searchText: searchBarText)
            case .completeSearchText: searchWithText(searchText: searchBarText)
            }
        } else {
            searchResultsUpdating = false
            // There is no search text
            // Clear current search results
            delegate?.searchResultsDidUpdate([], searchLocation: nil)
        }
    }
    
    private func partialSearchWithText(searchText: String) {
        if searchResultsUpdating == false {
            searchResultsUpdating = true
            // Notify the delegate when a new update
            // begins
            delegate?.searchResultsDidStartUpdating()
        }
        
        guard AppContext.shared.offlineContext.state == .online else {
            return
        }
        
        GDATelemetry.track("autosuggest.request_made", with: ["context": delegate?.telemetryContext ?? ""])
        
        searchRequestToken?.cancel()
        
        //
        // Fetch autosuggest results with new search text
        //

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let coordinate = self.location!.coordinate
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 75000, longitudinalMeters: 75000)
        let search = MKLocalSearch(request: request)
        search.start(completionHandler: searchWithTextCallback)
    }
}

// MARK: - UISearchBarDelegate

extension SearchResultsUpdater: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBarButtonClicked = true
        
        guard let searchBarText = searchBar.text, searchBarText.isEmpty == false else {
            // Return if there is no search text
            return
        }
        
        self.searchWithText(searchText: searchBarText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchWasCancelled()
    }
    
    private func searchWithText(searchText: String) {
        // Notify the delegate when a new update
        // begins
        delegate?.searchResultsDidStartUpdating()
        
        guard AppContext.shared.offlineContext.state == .online else {
            return
        }
        
        GDATelemetry.track("search.request_made", with: ["context": delegate?.telemetryContext ?? ""])
        
        searchRequestToken?.cancel()
        
        //
        // Fetch search results given search text
        //
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let coordinate = self.location!.coordinate
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 75000, longitudinalMeters: 75000)
        let search = MKLocalSearch(request: request)
        search.start(completionHandler: searchWithTextCallback)
    }
    
    private func searchWithTextCallback(using response: MKLocalSearch.Response?, error: Error?) -> Void {
        guard error == nil else {
            return
        }
        var pois: [POI] = []
        if let mapItems = response?.mapItems {
            for result in mapItems {
                let lat = result.placemark.location?.coordinate.latitude
                let long = result.placemark.location?.coordinate.longitude
                var addressParts: [String] = []
                if let substreet = result.placemark.subThoroughfare {
                    addressParts.append(substreet)
                }
                if let street = result.placemark.thoroughfare {
                    addressParts.append(street + ",")
                }
                if let city = result.placemark.locality {
                    addressParts.append(city)
                }
                if let state = result.placemark.administrativeArea {
                    addressParts.append(state + ",")
                }
                if let postalCode = result.placemark.postalCode {
                    addressParts.append(postalCode + ",")
                }
                if let country = result.placemark.country {
                    addressParts.append(country)
                }
                let address = addressParts.joined(separator: " ")
                pois.append(GenericLocation(lat: lat!, lon: long!, name: result.name!, address: address))
            }
        }
        delegate?.searchResultsDidUpdate(pois, searchLocation: self.location)
    }
    
}
