//
//  Sounds.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

typealias AsyncSoundsNotificationHandler = (_ notification: Notification) -> [Sound]

class Sounds {
    
    // MARK: Properties
    
    static var empty: Sounds {
        return Sounds()
    }
    
    private let lock = NSLock()
    private(set) var soundArray: [Sound]
    private var onNotificationHandler: AsyncSoundsNotificationHandler?
    private var notificationName: Notification.Name?
    private var notificationObject: Any?
    
    var isEmpty: Bool {
        return soundArray.isEmpty
    }
    
    // MARK: Initialization
        
    init(_ sounds: [Sound] = []) {
        self.soundArray = sounds
    }
    
    convenience init(_ sound: Sound) {
        self.init([sound])
    }
    
    convenience init(soundArray: [Sound], onNotificationHandler: AsyncSoundsNotificationHandler?, notificationName: Notification.Name?, notificationObject: Any?) {
        self.init(soundArray)
        
        self.onNotificationHandler = onNotificationHandler
        self.notificationName = notificationName
        self.notificationObject = notificationObject
        
        // We should have a value for `notificationName` to add an obeserver
        guard let notificationName = self.notificationName else {
            return
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onAsyncSoundsCompleted),
                                               name: notificationName,
                                               object: notificationObject)
    }
    
    // MARK: Iterate through array
    
    func next() -> Sound? {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        guard soundArray.count > 0 else {
            return nil
        }
        
        // Try to get next sound
        return soundArray.removeFirst()
    }
    
    // MARK: Notifications
    
    @objc private func onAsyncSoundsCompleted(_ notification: Notification) {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        guard let soundArray = onNotificationHandler?(notification) else {
            return
        }
        
        self.soundArray.append(contentsOf: soundArray)
    }
    
}
