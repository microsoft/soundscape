//
//  CompositeRecommender.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import SwiftUI
import Combine

/*
 * This recommender listens for updates from component recommenders and publishes
 * the update from the recommender with the highest priority. If no recommendations
 * are available, this class publishes a `nil` value.
 *
 * Recommender priority is represented by the `rawValue` of the `Component` enum.
 *
 */
class CompositeRecommender: Recommender {
    
    // MARK: Enum
    
    private enum Component: Int, CaseIterable {
        // `rawValue` represents the recommender's
        // priority
        case route
        
        var recommender: Recommender {
            switch self {
            case .route: return RouteRecommender()
            }
        }
        
        static var allSortedRecommenders: [Recommender] {
            // Return an array of all recommenders that is sorted
            // by the recommender's priority
            return Component.allCases
                .sorted(by: { $0.rawValue < $1.rawValue })
                .compactMap({ return $0.recommender })
        }
    }
    
    // MARK: Properties
    
    typealias RecommendationDictionary = [Int: (() -> AnyView)?]
    
    var publisher: CurrentValueSubject<RecommendationDictionary.Value, Never> = .init(nil)
    private var sortedRecommenders: [Recommender] = []
    private var prioritizedRecommendations: RecommendationDictionary = [:]
    private var listeners: [AnyCancellable] = []
    
    private var currentPrioritizedRecommendation: RecommendationDictionary.Element? {
        return prioritizedRecommendations.sorted(by: { return $0.key < $1.key }).first(where: { $0.value != nil })
    }
    
    // MARK: Initialization
    
    init() {
        // Save reference to recommenders
        sortedRecommenders = Component.allSortedRecommenders
        
        sortedRecommenders.enumerated().forEach { (priority, recommender) in
            // Save initial value
            prioritizedRecommendations[priority] = recommender.publisher.value
            
            // Listen for new values
            listeners.append(recommender.publisher.receive(on: RunLoop.main).sink(receiveValue: { [weak self] newValue in
                guard let `self` = self else {
                    return
                }
                
                // Save a reference to the current recommendation
                let oldValue = self.currentPrioritizedRecommendation
                
                // Save new value
                self.prioritizedRecommendations[priority] = newValue
                
                guard oldValue?.key != self.currentPrioritizedRecommendation?.key || self.currentPrioritizedRecommendation?.key == priority else {
                    // The current recommendation has not changed
                    return
                }
                
                // Update the current recommendation
                self.publisher.value = self.currentPrioritizedRecommendation?.value
            }))
        }
    }
    
}
