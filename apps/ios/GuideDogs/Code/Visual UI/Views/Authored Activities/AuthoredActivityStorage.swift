//
//  AuthoredActivityStorage.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Combine

struct ActivityModel {
    enum State {
        case active
        case complete
        case notComplete
    }
    
    let metadata: AuthoredActivityMetadata
    let content: AuthoredActivityContent
    let state: State
    
    init(_ meta: AuthoredActivityMetadata, _ content: AuthoredActivityContent) {
        self.metadata = meta
        self.content = content
        self.state = ActivityModel.state(for: content)
    }
    
    init(_ designActivity: AuthoredActivityContent, state: State) {
        self.metadata = AuthoredActivityMetadata(id: designActivity.id, linkVersion: .currentVersion(for: .experience))
        self.content = designActivity
        self.state = state
    }
    
    private static func state(for activity: AuthoredActivityContent) -> State {
        switch AppContext.shared.eventProcessor.activeBehavior {
        case let guidance as RouteGuidance:
            if guidance.content.id == activity.id {
                return .active
            }
            
            guard let state = RouteGuidanceState.load(id: activity.id) else {
                return .notComplete
            }
            
            return state.isFinal ? .complete : .notComplete
            
        case let guidance as GuidedTour:
            if guidance.content.id == activity.id {
                return .active
            }
            
            return guidance.state.isFinal ? .complete : .notComplete
            
        default:
            return .notComplete
        }
    }
}

final class AuthoredActivityStorage: ObservableObject {
    @Published var activities: [ActivityModel]
    
    private var listeners: [AnyCancellable] = []
    
    private var loader: AuthoredActivityLoader?
    
    init(_ loader: AuthoredActivityLoader) {
        self.loader = loader
        activities = loader.events.compactMap { metadata in
            guard let content = loader.loadContent(metadata.id) else {
                return nil
            }
            
            return ActivityModel(metadata, content)
        }
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorActivated).sink { _ in
            self.activities = self.activities.compactMap { ActivityModel($0.metadata, $0.content) }
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .behaviorDeactivated).sink { _ in
            self.activities = self.activities.compactMap { ActivityModel($0.metadata, $0.content) }
        })
        
        listeners.append(NotificationCenter.default.publisher(for: .activityDataUpdated).sink {  notification in
            guard let userInfo = notification.userInfo else {
                return
            }
            
            guard let id = userInfo[AuthoredActivityLoader.Keys.activityId] as? String else {
                return
            }
            
            guard let metadata = userInfo[AuthoredActivityLoader.Keys.metadata] as? AuthoredActivityMetadata else {
                return
            }
            
            guard let content = userInfo[AuthoredActivityLoader.Keys.content] as? AuthoredActivityContent else {
                return
            }
            
            self.activities = self.activities.compactMap {
                if $0.metadata.id == id {
                    return ActivityModel(metadata, content)
                } else {
                    return ActivityModel($0.metadata, $0.content)
                }
            }
        })
    }
    
    init(_ designTimeData: [(AuthoredActivityContent, ActivityModel.State)]) {
        activities = designTimeData.compactMap { ActivityModel($0.0, state: $0.1)}
    }
    
    deinit {
        listeners.cancelAndRemoveAll()
    }
    
    func reset(_ id: String?) {
        guard let id = id, let index = activities.firstIndex(where: { $0.metadata.id == id }) else {
            return
        }
        
        loader?.reset(id)
        
        guard let metadata = loader?.events.first(where: { $0.id == id }), let content = loader?.loadContent(id) else {
            return
        }
        
        activities[index] = ActivityModel(metadata, content)
    }
    
    func update(_ id: String?) {
        guard let id = id, let index = activities.firstIndex(where: { $0.metadata.id == id }) else {
            return
        }
        
        Task {
            guard let (metadata, content) = try await loader?.updateData(id) else {
                return
            }
            
            await MainActor.run {
                activities[index] = ActivityModel(metadata, content)
            }
        }
    }
    
    func remove(_ id: String?) {
        guard let id = id, let index = activities.firstIndex(where: { $0.metadata.id == id }) else {
            return
        }
        
        loader?.remove(id)
        activities.remove(at: index)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("behavior.experiences.delete.confirmation"))
        }
    }
}
