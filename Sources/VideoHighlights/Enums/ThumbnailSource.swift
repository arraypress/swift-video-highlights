//
//  ThumbnailSource.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// Where a report's thumbnail time came from.
public enum ThumbnailSource: String, Sendable, Codable, Equatable, Hashable {
    /// Apple's key frame.
    case keyFrame
    /// The middle of the best moment: Apple's key frame was 0 s, dark or flat.
    case topMoment
    /// The most engaging level segment: no moments, no usable key frame.
    case peakLevel
    /// The middle of the video: nothing better to go on.
    case middle
}
