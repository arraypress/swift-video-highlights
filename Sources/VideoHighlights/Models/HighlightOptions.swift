//
//  HighlightOptions.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// What to look for.
public struct HighlightOptions: Sendable, Codable, Equatable, Hashable {

    /// How many moments to return at most.
    public var top: Int

    /// The shortest a moment may be, in seconds. Apple's highlights are
    /// 2.5–10 s; shorter windows are widened into the video around them.
    public var minimumLength: Double

    /// The longest a moment may be, in seconds.
    public var maximumLength: Double

    /// Highlights closer together than this, in seconds, join one moment.
    public var joinGap: Double

    /// Analyse a 720p copy when the video is larger than 1080p — the same
    /// verdict, many times faster on 4K (measured: a 4.5K clip 1,081 s → 15 s).
    public var usesProxy: Bool

    public init(top: Int = 3, minimumLength: Double = 15, maximumLength: Double = 60,
                joinGap: Double = 2, usesProxy: Bool = true) {
        self.top = top
        self.minimumLength = minimumLength
        self.maximumLength = maximumLength
        self.joinGap = joinGap
        self.usesProxy = usesProxy
    }
}
