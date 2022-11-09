//
//  DiscreteAudioPlayer.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation
import AVFoundation

protocol DiscreteAudioPlayerDelegate: AnyObject {
    func onDataPlayedBack(_ playerId: AudioPlayerIdentifier)
    func onLayerFormatChanged(_ playerId: AudioPlayerIdentifier, layer: Int)
}

class DiscreteAudioPlayer: BaseAudioPlayer {
    
    /// Encapsulates all state related to an audio channel except for the node itself
    private struct LayerState {
        /// A promise that is fulfilled when the next buffer is finished being generated
        var bufferPromise: Promise<AVAudioPCMBuffer?>?
        
        /// A queue used for tracking which buffers have been scheduled to play but have not finished
        /// playing yet. This allows us to reschedule the pending buffers if the player is paused for
        /// any reason (e.g. an audio route change)
        var bufferQueue: Queue<AVAudioPCMBuffer> = .init()
        
        /// Counts the number of buffers played in this channel
        var bufferCount = 0
        
        /// Tracks if the playback dispatch group was entered or not for this layer
        var playbackDispatchGroupWasEntered = false
        
        /// Tracks if the playback dispatch group was left or not for this layer
        var playbackDispatchGroupWasLeft = false
    }
    
    weak var delegate: DiscreteAudioPlayerDelegate?
    
    private var layerStates: [LayerState]
    
    private var channelPrepareDispatchGroup = DispatchGroup()
    
    private var channelPlayedBackDispatchGroup = DispatchGroup()
    
    private var isCancelled = false
    
    private var wasPaused = false
    
    required init?(_ sound: Sound, queue: DispatchQueue) {
        layerStates = (0 ..< sound.layerCount).map { _ in LayerState() }
        
        super.init(sound: sound, queue: queue)
    }
    
    override func prepare(engine: AVAudioEngine, completion: ((_ success: Bool) -> Void)?) {
        state = .preparing
        
        guard let sound = sound as? Sound else {
            completion?(false)
            return
        }
        
        guard layerStates.count == layers.count else {
            completion?(false)
            return
        }
        
        for index in 0 ..< layers.count {
            channelPrepareDispatchGroup.enter()
            
            // Load the sound buffers
            layerStates[index].bufferPromise = sound.nextBuffer(forLayer: index)
            
            layerStates[index].bufferPromise?.then { [weak self] buffer in
                self?.queue.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    // Make sure we have a buffer
                    guard !self.isCancelled, let buffer = buffer else {
                        self.state = .notPrepared
                        self.channelPrepareDispatchGroup.leave()
                        return
                    }
                    
                    // TODO: What happens if the formats don't all agree...
                    self.layers[index].format = buffer.format
                    self.layers[index].attach(to: engine)
                    
                    self.layerStates[index].playbackDispatchGroupWasEntered = true
                    self.channelPlayedBackDispatchGroup.enter()
                    self.channelPrepareDispatchGroup.leave()
                }
            }
        }
        
        // Action to take when the channels all finish preparing
        channelPrepareDispatchGroup.notify(queue: queue) { [weak self] in
            guard self?.state == .preparing else {
                completion?(false)
                return
            }
            
            self?.state = .prepared
            self?.setupPlaybackDispatchGroup()
            completion?(true)
        }
    }
    
    private func setupPlaybackDispatchGroup() {
        // Action to take when all the channels finish playing back
        channelPlayedBackDispatchGroup.notify(queue: queue) { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.onDataPlayedBack(self.id)
        }
    }
    
    override func resumeIfNecessary() throws -> Bool {
        guard isPlaying else {
            return false
        }
        
        guard layers.contains(where: { !$0.isPlaying }) else {
            // Audio is still playing
            // "Resume" is successful
            return true
        }
        
        var resumed = false
        
        // Resume playback if the player has isPlaying set to true but the node is stopped
        for (index, layer) in layers.enumerated() where !layer.isPlaying {
            schedulePendingBuffers(forChannel: index)
            try layer.play()
            resumed = true
        }
        
        return resumed
    }
    
    override func scheduleBuffer(forLayer layer: Int) {
        guard layerStates.count > layer else {
            return
        }
        
        guard let bufferPromise = layerStates[layer].bufferPromise else {
            return
        }
        
        // Schedule the buffer to be played as soon as it is available
        bufferPromise.then { [weak self] (buffer) in
            guard let `self` = self else {
                return
            }
            
            let format = self.layers[layer].format
            if let buffer = buffer, buffer.format != format {
                GDLogAudioVerbose("Format needs to be updated (Old: \(format?.description ?? "Nil"), New: \(buffer.format))")
                
                // Schedule a silent buffer and wait for it to finish playing before reconnecting to the audio engine with the appropriate format...
                self.awaitSilentBuffer(for: layer) { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    GDLogAudioVerbose("Reconnecting for new format")
                    
                    self.layers[layer].stop()
                    self.layers[layer].format = buffer.format
                    self.delegate?.onLayerFormatChanged(self.id, layer: layer)
                    self.playBuffer(buffer, onChannel: layer)
                    
                    do {
                        try self.layers[layer].play()
                    } catch {
                        GDLogAudioError("Unable to restart the player after audio buffer format change in layer \(layer)")
                        
                        guard !self.layerStates[layer].playbackDispatchGroupWasLeft else {
                            return
                        }
                        
                        // Try to recover by indicating that this layer is done
                        self.layerStates[layer].playbackDispatchGroupWasLeft = true
                        self.channelPlayedBackDispatchGroup.leave()
                    }
                }
                
                return
            }
            
            self.queue.async {
                self.playBuffer(buffer, onChannel: layer)
            }
        }
    }
    
    private func schedulePendingBuffers(forChannel layer: Int) {
        guard layerStates.count > layer, layers.count > layer else {
            return
        }
        
        // Reset `wasPaused` so it will notify properly moving forward
        wasPaused = false
        
        // Schedule all the buffers in the pending buffer queue
        var oldQueue = layerStates[layer].bufferQueue
        var newQueue: Queue<AVAudioPCMBuffer> = .init()
        layerStates[layer].bufferQueue = newQueue
        
        while let buffer = oldQueue.dequeue() {
            newQueue.enqueue(buffer)
            layers[layer].player.scheduleBuffer(buffer, completionCallbackType: .dataRendered) { [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                
                // Only log completion and remove from the buffer queue if the audio actually played back
                guard !self.wasPaused else {
                    return
                }
                
                self.queue.async {
                    _ = self.layerStates[layer].bufferQueue.dequeue()
                }
            }
        }
        
        // Call the regular `scheduleBuffer` function to continue scheduling any future buffers.
        queue.async {
            self.scheduleBuffer(forLayer: layer)
        }
    }
    
    private func playBuffer(_ buffer: AVAudioPCMBuffer?, onChannel layer: Int) {
        guard layerStates.count > layer, layers.count > layer, layers[layer].isAttached else {
            GDLogAudioError("Node is no longer connected to the audio engine. Buffer cannot be played!")
            return
        }
        
        // If the buffer is nil, then the Sound object is done rendering buffers so we should
        // wait for all buffers that were scheduled to play to finish playing by having the
        // dispatch group notify us.
        guard let buffer = buffer else {
            layers[layer].player.scheduleBuffer(layers[layer].silentBuffer(), completionCallbackType: .dataPlayedBack) { [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                
                guard self.layerStates[layer].bufferQueue.isEmpty else {
                    self.wasPaused = true
                    return
                }

                guard self.layerStates[layer].playbackDispatchGroupWasEntered else {
                    GDLogAudioVerbose("Silent buffer played back, but dispatch group was never entered!")
                    return
                }
                
                guard !self.layerStates[layer].playbackDispatchGroupWasLeft else {
                    GDLogAudioVerbose("Silent buffer played back, but dispatch group was already left!")
                    return
                }
                
                self.layerStates[layer].playbackDispatchGroupWasLeft = true
                self.channelPlayedBackDispatchGroup.leave()
            }
            
            return
        }
        
        // Schedule this buffer (and use the dispatch group to know when it is done playing)
        layerStates[layer].bufferQueue.enqueue(buffer)
        layerStates[layer].bufferCount += 1
        layers[layer].player.scheduleBuffer(buffer, completionCallbackType: .dataRendered) { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            
            // Only log completion and remove from the buffer queue if the audio actually played back
            guard !self.wasPaused else {
                return
            }
            
            self.queue.async {
                _ = self.layerStates[layer].bufferQueue.dequeue()
            }
        }
        
        // Request the next buffer and schedule it
        guard let sound = sound as? Sound else {
            return
        }
        
        layerStates[layer].bufferPromise = sound.nextBuffer(forLayer: layer)
        scheduleBuffer(forLayer: layer)
    }
    
    private func awaitSilentBuffer(for layer: Int, callback: @escaping () -> Void) {
        guard layerStates.count > layer, layers.count > layer, layers[layer].isAttached else {
            GDLogAudioError("Node is no longer connected to the audio engine. Buffer cannot be played!")
            return
        }
        
        let silentBuffer = layers[layer].silentBuffer()
        
        layers[layer].player.scheduleBuffer(silentBuffer, completionCallbackType: .dataPlayedBack) { [weak self] (_) in
            self?.queue.async {
                callback()
            }
        }
    }
    
    override func stop() {
        // Allow for cancelling sounds that are still being prepared (e.g. async TTS that hasn't returned a buffer yet)
        guard state == .prepared else {
            if state == .preparing {
                isCancelled = true
            }
            
            return
        }
        
        super.stop()
    }
}
