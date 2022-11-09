//
//  AuthoredActivityLoader.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//
//  This is a convenience class that only exists until we have a long term solution for
//  locating/listing the available experiences to download.
//

import Foundation
import CoreLocation
import iOS_GPX_Framework

enum ActivityLoaderError: Error {
    case loadingError
    case urlUnavailable
    case noExperiencesFile
    case unableToSaveExperience
    case unableToLoadContent
    case experienceInvalid
}

extension Notification.Name {
    static let didTryActivityUpdate = Notification.Name("GDADidTryActivityUpdate")
    static let activityDataUpdated = Notification.Name("GDAEventDataUpdated")
    static let activityStateReset = Notification.Name("GDEventStateReset")
    static let activityAllAudioDownloaded = Notification.Name("GDAActivityAudioDownloaded")
    static let activityAudioClipDownloaded = Notification.Name("GDAAudioClipDownloaded")
}

protocol AuthoredActivityContentLoader {
    func loadContent() -> AuthoredActivityContent?
}

struct KnownActivities: Codable {
    var events: [AuthoredActivityMetadata]
}

class AuthoredActivityLoader {
    struct Keys {
        static let activityId = "activityId"
        static let remotePath = "remotePath"
        static let localPath = "localPath"
        static let updateAvailable = "updateAvailable"
        static let updateSuccess = "success"
        static let metadata = "metadata"
        static let content = "content"
    }
    
    static let shared: AuthoredActivityLoader = AuthoredActivityLoader()
    
    // MARK: - Experiences
    
    private var knownActivities: KnownActivities
    
    var events: [AuthoredActivityMetadata] {
        return knownActivities.events
    }
    
    private let networkClient: NetworkClient
    
    // MARK: - URLS
    
    private var metadataURL: URL? {
        guard let dir = activitiesDirectory else {
            return nil
        }
        
        return dir.appendingPathComponent("experiences.json")
    }
    
    // MARK: - Methods
    
    init(_ activities: [AuthoredActivityMetadata], _ networkClient: NetworkClient = URLSession.shared) {
        knownActivities = KnownActivities(events: activities)
        self.networkClient = networkClient
    }
    
    private convenience init() {
        self.init([])
        
        guard let url = metadataURL, FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        
        guard let data = try? Data(contentsOf: url), let activities = try? JSONDecoder().decode(KnownActivities.self, from: data) else {
            return
        }
        
        knownActivities = activities
    }
    
    func activityExists(_ activityID: String) -> Bool {
        return knownActivities.events.contains(where: { $0.id == activityID })
    }
    
    func audioClipExists(activityID: String, remoteURL: URL) -> Bool {
        guard let localURL = localAudioFileURL(activityID: activityID, remoteURL: remoteURL) else {
            return false
        }
        
        return FileManager.default.fileExists(atPath: localURL.path)
    }
    
    func hasState(_ activityID: String) -> Bool {
        guard let url = stateURL(activityID: activityID) else {
            return false
        }
        
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func loadContent(_ activityID: String) -> AuthoredActivityContent? {
        guard let contentURL = contentURL(activityID: activityID) else {
            GDLogAppError("Shared content GPX file does not exist for id: \(activityID)")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: contentURL.path) else {
            GDLogAppError("Unable to get the shared content GPX file path for ID: \(activityID)")
            return nil
        }
        
        guard let gpx = GPXParser.parseGPX(at: contentURL) else {
            return nil
        }
        
        // Parse the GPX file and validate its contents
        return AuthoredActivityContent.parse(gpx: gpx)
    }
    
    func add(_ activityID: String, linkVersion: UniversalLinkVersion) async throws {
        if knownActivities.events.contains(where: { $0.id == activityID }) {
            return
        }
        
        do {
            _ = try await downloadContentAsync(for: AuthoredActivityMetadata(id: activityID, linkVersion: linkVersion))
            GDATelemetry.track("asevents.added")
        } catch {
            // TODO: Differentiate between the various errors that can be thrown
            
            GDLogError(.network, "Unable to save downloaded experience data (id: \(activityID)")
            GDATelemetry.track("asevents.update.failure", with: ["reason": "fileError"])
            
            throw ActivityLoaderError.unableToSaveExperience
        }
    }
    
    func remove(_ activityID: String) {
        // Get a copy of the activity content so we can delete all downloaded audio clips
        if let content = loadContent(activityID) {
            removeCachedImages(for: content)
        }
        
        guard let index = knownActivities.events.firstIndex(where: { $0.id == activityID }) else {
            return
        }
        
        knownActivities.events.remove(at: index)
        
        do {
            try saveKnownActivities()
            
            // Delete the audio files if any exist
            if let dir = audioDirectoryURL(activityID: activityID) {
                if FileManager.default.fileExists(atPath: dir.path) {
                    try FileManager.default.removeItem(at: dir)
                }
            }
            
            // Delete the state file if one exists
            guard let state = stateURL(activityID: activityID) else {
                GDLogAppError("Unable to get state file URL")
                return
            }
            
            if FileManager.default.fileExists(atPath: state.path) {
                try FileManager.default.removeItem(at: state)
            }
            
            // Delete the content file if one exists
            guard let contentURL = contentURL(activityID: activityID) else {
                GDLogAppError("Unable to get content file URL")
                return
            }
            
            if FileManager.default.fileExists(atPath: contentURL.path) {
                try FileManager.default.removeItem(at: contentURL)
            }
            
            GDATelemetry.track("asevents.removed")
        } catch {
            GDLogAppError("Unable to save known experiences file or remove content/state files!")
        }
    }
    
    func reset(_ activityID: String) {
        guard let url = stateURL(activityID: activityID) else {
            GDLogAppError("Unable to reset state file!")
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            // No state to delete
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
            NotificationCenter.default.post(name: .activityStateReset, object: nil, userInfo: [Keys.activityId: activityID])
            GDATelemetry.track("asevents.reset")
        } catch {
            GDLogAppError("Unable to reset state file!")
        }
    }
    
    func updateData(_ activityID: String) async throws -> (AuthoredActivityMetadata, AuthoredActivityContent)? {
        guard let index = knownActivities.events.firstIndex(where: { activityID == $0.id }) else {
            return nil
        }
        
        return try await downloadContentAsync(for: knownActivities.events[index])
    }
    
    private func downloadContentAsync(for activity: AuthoredActivityMetadata) async throws -> (AuthoredActivityMetadata, AuthoredActivityContent) {
        var metadata = activity
        let id = metadata.id
        
        guard let url = metadata.downloadPath else {
            GDATelemetry.track("asevents.update.failure", with: ["reason": "urlUnavailable"])
            
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: false,
                Keys.updateAvailable: true
            ])
            
            throw ActivityLoaderError.urlUnavailable
        }
        
        // Build the request and include the known etag if one exists
        let isInitialDownload = metadata.etag == nil
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20.0)
        
        if let etag = metadata.etag {
            request.setValue(etag, forHTTPHeaderField: HTTPHeader.ifNoneMatch.rawValue)
        }
        
        // Request the data from the server
        let (data, response) = try await networkClient.requestData(request)
        
        // If it wasn't modified, then return the current content
        if response.statusCode == .notModified, let content = loadContent(id) {
            GDLogInfo(.routeGuidance, "Activity data has not been modified since it was last downloaded.")
            GDATelemetry.track("asevents.update.success", with: ["modified": "false"])
            
            // Start downloading the audio clips and images in case any still need to be cached
            Task {
                await cacheContent(for: content)
            }
            
            UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("behavior.experiences.reset.confirmation"))
            
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: false,
                Keys.updateAvailable: false
            ])
            
            return (metadata, content)
        }
        
        // If the we received any other response code, then an error occurred
        guard response.statusCode == .success else {
            GDLogWarn(.routeGuidance, "HTTP response does not indicate success. Unable to load content.")
            GDATelemetry.track("asevents.update.failure", with: ["reason": "badStatusCode"])
            
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: false,
                Keys.updateAvailable: true
            ])
            
            throw ActivityLoaderError.unableToLoadContent
        }
        
        // Validate that we can parse the new data
        guard let gpx = GPXParser.parseGPX(with: data) else {
            GDLogWarn(.routeGuidance, "Unable to parse GPX for \(id)")
            
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: false,
                Keys.updateAvailable: true
            ])
            
            throw ActivityLoaderError.unableToLoadContent
        }
        
        guard let content = AuthoredActivityContent.parse(gpx: gpx) else {
            GDLogWarn(.routeGuidance, "Unable to parse activity content from GPX for \(id)")
            
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: false,
                Keys.updateAvailable: true
            ])
            
            throw ActivityLoaderError.unableToLoadContent
        }
        
        // Save the downloaded data
        guard let contentURL = contentURL(activityID: id) else {
            GDATelemetry.track("asevents.update.failure", with: ["reason": "urlUnavailable"])
            
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: false,
                Keys.updateAvailable: true
            ])
            
            throw ActivityLoaderError.urlUnavailable
        }
        
        try data.write(to: contentURL)
        GDATelemetry.track("asevents.update.success", with: ["modified": "true"])
        GDLogInfo(.routeGuidance, "Activity downloaded successfully!")
        
        // Update the metadata and store it
        if let etag = response.allHeaderFields[HTTPHeader.eTag.rawValue] as? String {
            metadata.etag = etag
        }
        
        if let index = knownActivities.events.firstIndex(where: { $0.id == id }) {
            knownActivities.events[index] = metadata
        } else {
            // This is the first time the activity has been downloaded, so save it
            knownActivities.events.append(metadata)
        }
        
        try self.saveKnownActivities()
        GDLogInfo(.routeGuidance, "Known activities file updated.")
        
        // If the experience was updated and it wasn't the first time it was being downloaded, then
        // post an accessibility announcement for VoiceOver users
        
        if !isInitialDownload {
            UIAccessibility.post(notification: .announcement, argument: GDLocalizedString("behavior.experiences.reset.confirmation"))
        }
        
        NotificationCenter.default.post(name: .activityDataUpdated, object: nil, userInfo: [Keys.activityId: metadata.id, Keys.metadata: metadata, Keys.content: content])
        
        if !isInitialDownload {
            NotificationCenter.default.post(name: .didTryActivityUpdate, object: self, userInfo: [
                Keys.updateSuccess: true,
                Keys.updateAvailable: true
            ])
        }
        
        // Start downloading the audio clips and images
        Task {
            await cacheContent(for: content)
        }
        
        return (metadata, content)
    }
    
    private func saveKnownActivities() throws {
        guard let url = metadataURL else {
            throw ActivityLoaderError.loadingError
        }
        
        // Save state file
        let data = try JSONEncoder().encode(knownActivities)
        try data.write(to: url)
    }
    
    func cacheContent(for content: AuthoredActivityContent) async {
        // Cache the featured image first since this is what users will see first
        if let featured = content.image {
            await cacheImage(featured)
        }
        
        // Then cache the remaining audio clips and images
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                GDLogInfo(.routeGuidance, "Checking for audio clips to download...")
                await self.downloadAudioClips(content)
            }
        
            group.addTask {
                GDLogInfo(.routeGuidance, "Checking for images to download...")
                await self.downloadImages(content)
            }
            
            await group.waitForAll()
        }
    }
    
    func downloadAudioClips(_ content: AuthoredActivityContent) async {
        guard let metadata = knownActivities.events.first(where: { $0.id == content.id }) else {
            GDLogError(.authoredContent, "Unable to find known activity metadata! Cannot download audio clips...")
            return
        }
        
        for (key, value) in metadata.contentEtags {
            print("\(key): \(value)")
        }
        
        await withTaskGroup(of: (String, String?).self) { group in
            for (wptIndex, waypoint) in content.waypoints.enumerated() {
                for (clipIndex, audioClip) in waypoint.audioClips.enumerated() {
                    // Look up where the audio file should be stored locally
                    guard let localURL = self.localAudioFileURL(activityID: content.id, remoteURL: audioClip.url) else {
                        GDLogError(.authoredContent, "Unable to determine local file URL for audio clip \(audioClip.url.lastPathComponent) (waypoint: \(wptIndex), clip: \(clipIndex))")
                        continue
                    }
                    
                    group.addTask {
                        let updatedETag = await self.downloadAudioClip(audioClip,
                                                                       localURL: localURL,
                                                                       currentEtag: metadata.contentEtags[audioClip.url.lastPathComponent],
                                                                       wptIndex: wptIndex,
                                                                       clipIndex: clipIndex)
                        
                        NotificationCenter.default.post(name: .activityAudioClipDownloaded, object: nil, userInfo: [
                            Keys.activityId: content.id,
                            Keys.remotePath: audioClip.url.path,
                            Keys.localPath: localURL.path
                        ])
                        
                        return (localURL.lastPathComponent, updatedETag)
                    }
                }
            }
            
            let updatedEtags: [String: String] = await group.reduce(into: [:]) { partialResult, next in
                if let etag = next.1 {
                    partialResult[next.0] = etag
                }
            }
            
            if let index = knownActivities.events.firstIndex(where: { $0.id == metadata.id }) {
                var updatedMetadata = metadata
                updatedMetadata.contentEtags = metadata.contentEtags.merging(updatedEtags, uniquingKeysWith: { return $1 })
                knownActivities.events[index] = updatedMetadata
                
                do {
                    try self.saveKnownActivities()
                    GDLogInfo(.authoredContent, "Known activities file updated with audio clip etags.")
                } catch {
                    GDLogError(.authoredContent, "Unable to save updated etags for audio clips")
                }
            }
            
            GDLogInfo(.routeGuidance, "Finished downloading audio clips for \(content.id)")
            NotificationCenter.default.post(name: .activityAllAudioDownloaded, object: nil, userInfo: [Keys.activityId: content.id])
        }
    }
    
    private func downloadAudioClip(_ audioClip: ActivityWaypointAudioClip, localURL: URL, currentEtag: String?, wptIndex: Int, clipIndex: Int) async -> String? {
        GDLogInfo(.authoredContent, "Requesting audio clip \(audioClip.url.lastPathComponent) (waypoint: \(wptIndex), clip: \(clipIndex))")
        
        var request = URLRequest(url: audioClip.url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: ServiceModel.requestTimeout)
        
        if let etag = currentEtag {
            request.setValue(etag, forHTTPHeaderField: HTTPHeader.ifNoneMatch.rawValue)
        }
        
        do {
            let (data, response) = try await self.networkClient.requestData(request)
            
            if response.statusCode == .notModified {
                GDLogVerbose(.authoredContent, "Audio clip \(audioClip.url.lastPathComponent) already cached (waypoint: \(wptIndex), clip: \(clipIndex))")
                return currentEtag
            }
            
            guard response.statusCode == .success else {
                GDLogVerbose(.authoredContent, "Audio clip \(audioClip.url.lastPathComponent) failed to download (waypoint: \(wptIndex), clip: \(clipIndex))")
                return currentEtag
            }
            
            if FileManager.default.fileExists(atPath: localURL.path) {
                try FileManager.default.removeItem(at: localURL)
            }
            
            FileManager.default.createFile(atPath: localURL.path, contents: data)
            GDLogInfo(.authoredContent, "Successfully stored \(localURL.path) (bytes: \(data.count))")
            
            guard let updatedEtag = response.allHeaderFields[HTTPHeader.eTag.rawValue] as? String else {
                GDLogVerbose(.authoredContent, "ETag property not returned for audio clip \(audioClip.url.lastPathComponent) (waypoint: \(wptIndex), clip: \(clipIndex))")
                return currentEtag
            }
            
            return updatedEtag
            
        } catch {
            GDLogInfo(.authoredContent, "Failed to download or store \(audioClip.url)")
            return currentEtag
        }
    }
    
    private func downloadImages(_ content: AuthoredActivityContent) async {
        await withTaskGroup(of: Void.self) { group in
            let manager = SDWebImageManager.shared
            
            for (wptIndex, waypoint) in content.waypoints.enumerated() {
                for (clipIndex, image) in waypoint.images.enumerated() {
                    guard let key = manager.cacheKey(for: image.url), await manager.imageCache.containsImage(forKey: key, cacheType: .all) == .none else {
                        GDLogInfo(.authoredContent, "Image \(image.url.lastPathComponent) already cached (waypoint: \(wptIndex), clip: \(clipIndex))")
                        continue
                    }
                    
                    group.addTask {
                        GDLogInfo(.authoredContent, "Requesting image \(image.url.lastPathComponent) (waypoint: \(wptIndex), clip: \(clipIndex))")
                        await self.cacheImage(image.url)
                    }
                }
            }
            
            await group.waitForAll()
        }
        
        GDLogInfo(.routeGuidance, "Finished downloading images for \(content.id)")
    }
    
    private func cacheImage(_ url: URL) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            SDWebImageManager.shared.loadImage(with: url, progress: nil) { _, _, error, _, _, _ in
                if let error = error {
                    GDLogWarn(.routeGuidance, "Failed to cache image \(url.lastPathComponent) (\(error.localizedDescription)")
                } else {
                    GDLogInfo(.routeGuidance, "Cached image \(url.lastPathComponent)")
                }
                
                continuation.resume()
            }
        }
    }
    
    private func removeCachedImages(for content: AuthoredActivityContent) {
        let manager = SDWebImageManager.shared
        var images: [URL] = content.waypoints.flatMap({ $0.images.map { $0.url } })
        
        if let featured = content.image {
            images.append(featured)
        }
        
        for image in images {
            if let key = manager.cacheKey(for: image) {
                manager.imageCache.removeImage(forKey: key, cacheType: .all)
            }
        }
    }
    
    // MARK: Directories
    
    private var activitiesDirectory: URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let dir = documents.appendingPathComponent("SharedExperiences")
        
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return dir
    }
    
    private func contentURL(activityID: String) -> URL? {
        guard let dir = activitiesDirectory else {
            return nil
        }
        
        return dir.appendingPathComponent("\(activityID).gpx")
    }
    
    private func stateURL(activityID: String) -> URL? {
        guard let dir = activitiesDirectory else {
            return nil
        }
        
        let stateDir = dir.appendingPathComponent("State")
        
        if !FileManager.default.fileExists(atPath: stateDir.path) {
            do {
                try FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return stateDir.appendingPathComponent("\(activityID).json")
    }
    
    private func audioDirectoryURL(activityID: String) -> URL? {
        guard let dir = activitiesDirectory else {
            return nil
        }
        
        let audioDir = dir.appendingPathComponent("Audio").appendingPathComponent(activityID)
        
        if !FileManager.default.fileExists(atPath: audioDir.path) {
            do {
                try FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return audioDir
    }
    
    func localAudioFileURL(activityID: String, remoteURL: URL) -> URL? {
        guard let dir = audioDirectoryURL(activityID: activityID) else {
            return nil
        }
        
        return dir.appendingPathComponent(remoteURL.lastPathComponent)
    }
}
