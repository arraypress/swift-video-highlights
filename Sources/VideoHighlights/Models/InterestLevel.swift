//
//  InterestLevel.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// How engaging one short segment of the video is, as Apple's analysis
/// scores it: 0 (least) to 9 (most), about every half second.
public struct InterestLevel: Sendable, Codable, Equatable, Hashable {

    /// Where the segment starts, in seconds.
    public let start: Double

    /// Where the segment ends, in seconds.
    public let end: Double

    /// 0–9.
    public let level: Double

    public init(start: Double, end: Double, level: Double) {
        self.start = start
        self.end = end
        self.level = level
    }
}
