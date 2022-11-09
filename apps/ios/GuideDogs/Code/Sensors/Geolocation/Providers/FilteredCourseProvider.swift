//
//  FilteredCourseProvider.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class FilteredCourseProvider: CourseProvider {
    
    // MARK: Properties
    
    let id: UUID = .init()
    
    weak var courseDelegate: CourseProviderDelegate?
    private var rawCourseProvider: RawCourseProvider
    private var timer: Timer?
    
    private var isInMotion: Bool {
        didSet {
            guard oldValue != isInMotion else {
                return
            }
            
            if isInMotion == false {
                courseDelegate?.courseProvider(self, didUpdateCourse: nil)
            }
        }
    }
    
    // MARK: Initialization
    
    init(rawCourseProvider: RawCourseProvider, isInMotion: Bool) {
        self.rawCourseProvider = rawCourseProvider
        self.isInMotion = isInMotion
        
        // Initialize `RawCourseProviderDelegate`
        self.rawCourseProvider.courseDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onIsInMotionDidChange(_:)), name: Notification.Name.isInMotionDidChange, object: nil)
    }
    
    // MARK: `CourseProvider`
    
    func startCourseProviderUpdates() {
        rawCourseProvider.startCourseProviderUpdates()
    }
    
    func stopCourseProviderUpdates() {
        rawCourseProvider.stopCourseProviderUpdates()
    }
    
    // MARK: Notifications
    
    @objc
    private func onIsInMotionDidChange(_ notification: Notification) {
        guard let isInMotion = notification.userInfo?[MotionActivityContext.NotificationKeys.isInMotion] as? Bool else {
            return
        }
        
        self.isInMotion = isInMotion
    }
    
}

extension FilteredCourseProvider: RawCourseProviderDelegate {
    
    func courseProvider(_ provider: RawCourseProvider, didUpdateCourse course: HeadingValue?, speed: Double?) {
        // `course` is invalid if the user is not moving
        guard isInMotion else {
            return
        }
        
        if let speed = speed {
            // `course` is invalid if `speed` is too low
            guard speed >= 0.4 else {
                return
            }
        }
        
        timer?.invalidate()
        
        // Propogate `course`
        courseDelegate?.courseProvider(self, didUpdateCourse: course)

        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { (_) in
            // Course has not been updated within the expected
            // interval
            // Propogate `nil`
            self.courseDelegate?.courseProvider(self, didUpdateCourse: nil)
        })
    }
    
}
