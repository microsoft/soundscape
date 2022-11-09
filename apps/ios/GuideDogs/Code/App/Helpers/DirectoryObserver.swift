//
//  DirectoryObserver.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

protocol DirectoryObserverDelegate: AnyObject {
    func eventDispatched(for directoryObserver: DirectoryObserver)
}

/// A class to observer file directory changes. A block will be called when any change to a directory is made (write, delete, rename, etc...).
class DirectoryObserver {
    private let url: URL
    private weak var delegate: DirectoryObserverDelegate?
    
    private var fileDescriptor: CInt?
    private var source: DispatchSourceProtocol?
    
    init(url: URL, delegate: DirectoryObserverDelegate) {
        self.url = url
        self.delegate = delegate
    }
    
    deinit {
        stopObserving()
    }
    
    func startObserving() {
        fileDescriptor = open(url.path, O_EVTONLY)
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor!, eventMask: .all, queue: DispatchQueue.global())
        source!.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            if let delegate = self.delegate {
                delegate.eventDispatched(for: self)
            }
        }
        source!.resume()
    }
    
    func stopObserving() {
        if let source = source {
            source.cancel()
        }
        
        if let fileDescriptor = fileDescriptor {
            close(fileDescriptor)
        }
    }
}
