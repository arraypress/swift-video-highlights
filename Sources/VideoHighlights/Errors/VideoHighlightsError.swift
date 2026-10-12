//
//  VideoHighlightsError.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What can go wrong finding highlights. "Nothing engaging" is not one of
/// them: that is a report with no moments.
public enum VideoHighlightsError: Error, LocalizedError, Sendable, Equatable {

    /// No file there.
    case fileNotFound(String)

    /// A file AVFoundation cannot read as a movie.
    case unreadable(String)

    /// A movie with no picture — an audio file, say. (Apple's own answer for
    /// one is a misleading "timed out".)
    case noVideoTrack(String)

    /// This system cannot analyse video: MediaIntelligence needs macOS /
    /// iOS 27, or this build was made with an SDK that lacked it.
    case unavailable

    /// Making the 720p copy failed.
    case proxyFailed(String)

    /// Apple's analysis returned a failure.
    case analysisFailed(String)

    /// The options cannot be met (e.g. a shortest length above the longest).
    case invalidOptions(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path): "No file at \(path)"
        case .unreadable(let why): "Not a video this can read: \(why)"
        case .noVideoTrack(let path): "\(path) has no video track"
        case .unavailable: "Video highlights need macOS 27 or iOS 27 (Apple's MediaIntelligence)"
        case .proxyFailed(let why): "Could not make the 720p copy to analyse: \(why)"
        case .analysisFailed(let why): "The highlight analysis failed: \(why)"
        case .invalidOptions(let why): why
        }
    }
}
