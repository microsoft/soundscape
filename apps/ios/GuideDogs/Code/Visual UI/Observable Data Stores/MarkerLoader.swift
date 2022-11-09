//
//  MarkerLoader.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Combine

class MarkerLoader: ObservableObject {
    let queue = DispatchQueue(label: "com.company.appname.markerloader")
    
    @Published var loadingComplete = false
    @Published var markerIDs: [String] = []
    
    private var currentSort: SortStyle = .alphanumeric
    private var tokens: [AnyCancellable] = []
    
    deinit {
        tokens.cancelAndRemoveAll()
    }
    
    func load(sort: SortStyle) {
        currentSort = sort
        
        queue.async {
            let sortedKeys = ReferenceEntity.objectKeys(sortedBy: sort)
            
            DispatchQueue.main.async { [weak self] in
                // Initialize markers sorted by the given predicate (e.g. alphanumeric or distance)
                self?.markerIDs = sortedKeys
                self?.loadingComplete = true
                self?.listenForChanges()
            }
        }
    }
    
    func remove(id: String) throws {
        guard let index = markerIDs.firstIndex(where: { $0 == id }) else {
            return
        }
        
        markerIDs.remove(at: index)
        
        try ReferenceEntity.remove(id: id)
        UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("markers.action.deleted"))
    }
    
    private func listenForChanges() {
        tokens.append(NotificationCenter.default.publisher(for: .markerAdded).receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.load(sort: self.currentSort)
        })
        
        tokens.append(NotificationCenter.default.publisher(for: .markerRemoved).receive(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.load(sort: self.currentSort)
        })
    }
}
