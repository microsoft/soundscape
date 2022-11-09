//
//  RecommenderViewModel.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI
import Combine

/*
 * This view model listens for recommendation updates from the `CompositeRecommender` and
 * listens to various state within the app which decides whether it is an appropriate time to present
 * the recommendation view (`shouldPublish`).
 *
 * When a recommendation is available, and `shouldPublish = true` the view model publishes the
 * recommendation, else the view model publishes a `nil` value, and an empty view is presented in the corresponding
 * view (`RecommenderView`).
 *
 */
class RecommenderViewModel: ObservableObject {
    
    // MARK: Properties
    
    @Published private(set) var content: (() -> AnyView)?
    
    private var listeners: [AnyCancellable] = []
    private let recommender: Recommender
    private var currentContent: (() -> AnyView)?
    
    private var shouldPublish: Bool {
        return AppContext.shared.eventProcessor.activeBehavior is SoundscapeBehavior && AppContext.shared.spatialDataContext.destinationManager.isDestinationSet == false
    }
    
    // MARK: Initialization
    
    init(recommender: Recommender = CompositeRecommender()) {
        self.recommender = recommender
        
        // Listen for updates from the recommender
        listeners.append(recommender.publisher.receive(on: RunLoop.main).sink(receiveValue: { [weak self] newValue in
            guard let `self` = self else {
                return
            }
            
            // Save new value
            self.currentContent = newValue
            
            guard self.shouldPublish else {
                return
            }
            
            // Publish new value
            self.content = newValue
        }))
        
        //
        // Listen for updates that could change `shouldPublish`
        //
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorActivated).receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.onShouldPublishDidChange()
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorDeactivated).receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.onShouldPublishDidChange()
        }))
        
        listeners.append(NotificationCenter.default.publisher(for: .destinationChanged).receive(on: RunLoop.main).sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.onShouldPublishDidChange()
        }))
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
    private func onShouldPublishDidChange() {
        if self.shouldPublish && self.content == nil {
            self.content = self.currentContent
        } else if self.shouldPublish == false && self.content != nil {
            self.content = nil
        }
    }
    
}
