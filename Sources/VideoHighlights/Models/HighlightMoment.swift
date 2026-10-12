//
//  HighlightMoment.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// One stretch of a video worth cutting out: a clip-length window built from
/// Apple's highlights, ranked by how engaging it scored.
public struct HighlightMoment: Sendable, Codable, Equatable, Hashable {

    /// 1 for the best moment.
    public let rank: Int

    /// Where it starts, in seconds of the original video.
    public let start: Double

    /// Where it ends, in seconds of the original video.
    public let end: Double

    /// The mean interest level across the window, 0–9.
    public let score: Double

    /// The highest interest level inside the window, 0–9.
    public let peak: Double

    /// How many of Apple's highlights the window joins.
    public let highlights: Int

    public init(rank: Int, start: Double, end: Double, score: Double, peak: Double, highlights: Int) {
        self.rank = rank
        self.start = start
        self.end = end
        self.score = score
        self.peak = peak
        self.highlights = highlights
    }
}
