//
//  WaveAudioParser.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import Foundation

class WaveAudioParser: AudioParser {
    
    // MARK: Properties
    
    static private let riffMarker = "RIFF"
    static private let fmtMarker = "fmt "
    static private let dataMarker = "data"
    
    // Bytes for sample rate (UInt32) in fmt chunk
    static private let fmtSampleRateByteRange: Range = 12..<(12 + MemoryLayout<UInt32>.size)
    // Bytes for marker in any chunk
    static private let chunkMarkerByteRange: Range = 0..<4
    // Bytes for size (UInt32) in any subchunk (e.g. excluding RIFF marker)
    static private let subchunkSizeByteRange: Range = 4..<(4 + MemoryLayout<UInt32>.size)

    // Size (in bytes) of RIFF marker
    static private let chunkHeaderSize = 12
    // Size (in bytes) of any subchunk
    static private let subchunkHeaderSize = 8
    
    // MARK: Protocol
    
    static func getAudioData(data: Data) -> Data? {
        guard let dataBytes = getChunkWithMarker(data: data, marker: dataMarker) else {
            // Data marker is missing
            return nil
        }
        
        guard subchunkHeaderSize < dataBytes.count else {
            // Data is invalid
            return nil
        }
        
        // Remove subchunk header
        return dataBytes.advanced(by: subchunkHeaderSize)
    }
    
    static func getSampleRate(data: Data) -> UInt32? {
        guard let fmtBytes = getChunkWithMarker(data: data, marker: fmtMarker) else {
            // Format marker is missing
            return nil
        }
        
        guard fmtSampleRateByteRange.upperBound <= fmtBytes.count else {
            // Format marker is invalid
            return nil
        }
        
        // Read sample rate from Format chunk
        let sampleRateBytes = fmtBytes.subdata(in: fmtSampleRateByteRange)
        return sampleRateBytes.withUnsafeBytes({ $0.load(as: UInt32.self) })
    }
    
    // MARK: Parse Wave Data
    
    static private func getChunkWithMarker(data: Data, marker: String) -> Data? {
        guard let (currentMarker, currentSize) = parseChunk(data: data) else {
            // Failed to parse chunk
            return nil
        }
        
        if currentMarker == marker {
            guard currentSize <= data.count else {
                // Failed to parse current size
                return nil
            }
            
            return data.subdata(in: 0..<currentSize)
        }
        
        guard currentSize < data.count else {
            // Failed to parse current size
            return nil
        }
        
        // Advance to next marker
        return getChunkWithMarker(data: data.advanced(by: currentSize), marker: marker)
    }
    
    static private func parseChunk(data: Data) -> (marker: String?, size: Int)? {
        guard chunkMarkerByteRange.upperBound <= data.count else {
            // Cannot parse chunk marker
            return nil
        }
        
        let markerBytes = data.subdata(in: chunkMarkerByteRange)
        guard let marker = String(bytes: markerBytes, encoding: .utf8) else {
            return nil
        }
        
        if marker == riffMarker {
            guard chunkHeaderSize <= data.count else {
                // RIFF header is invalid
                return nil
            }
            
            // RIFF header will always be 12 bytes
            return (marker: marker, size: chunkHeaderSize)
        }
        
        guard subchunkSizeByteRange.upperBound <= data.count else {
            // Cannot parse chunk size
            return nil
        }
        
        let sizeBytes = data.subdata(in: subchunkSizeByteRange)
        let size = sizeBytes.withUnsafeBytes({ $0.load(as: UInt32.self )})
        
        guard size < data.count else {
            // Size is invalid
            return nil
        }
        
        return (marker: marker, size: subchunkHeaderSize + Int(size))
    }
    
}
