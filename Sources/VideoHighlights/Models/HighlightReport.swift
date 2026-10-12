//
//  HighlightReport.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// Everything one analysis found.
public struct HighlightReport: Sendable, Codable, Equatable, Hashable {

    /// The video's length, in seconds.
    public let duration: Double

    /// The best moments, best first. Empty is a real answer: slow,
    /// low-motion footage scores zero throughout.
    public let moments: [HighlightMoment]

    /// Apple's raw highlights, as start/end pairs in seconds, in time order.
    public let highlights: [ClosedRange<Double>]

    /// The interest level through the whole video.
    public let levels: [InterestLevel]

    /// Apple's key frame, in seconds — `nil` when it had no opinion (it
    /// answers 0 for any clip of two minutes or less).
    public let keyFrame: Double?

    /// Where a thumbnail should come from: the key frame when it is usable,
    /// otherwise the middle of the best moment.
    public let thumbnail: Double

    /// Why the thumbnail time is what it is.
    public let thumbnailSource: ThumbnailSource

    /// Whether a 720p copy was analysed instead of the original.
    public let usedProxy: Bool

    /// How long the analysis took, in seconds (the proxy included).
    public let seconds: Double

    public init(duration: Double, moments: [HighlightMoment], highlights: [ClosedRange<Double>],
                levels: [InterestLevel], keyFrame: Double?, thumbnail: Double,
                thumbnailSource: ThumbnailSource, usedProxy: Bool, seconds: Double) {
        self.duration = duration
        self.moments = moments
        self.highlights = highlights
        self.levels = levels
        self.keyFrame = keyFrame
        self.thumbnail = thumbnail
        self.thumbnailSource = thumbnailSource
        self.usedProxy = usedProxy
        self.seconds = seconds
    }
}
