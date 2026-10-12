//
//  ThumbnailChoice.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//

/// Which moment of the video makes the thumbnail.
enum ThumbnailChoice {

    /// Apple's key frame when it gave one (not 0 s) and the frame there is
    /// worth looking at; otherwise the middle of the best moment, the most
    /// engaging level segment, or the middle of the video, in that order.
    static func time(keyFrame: Double?, keyFrameUsable: Bool, moments: [HighlightMoment],
                     levels: [InterestLevel], duration: Double) -> (seconds: Double, source: ThumbnailSource) {
        if let keyFrame, keyFrame > 0, keyFrameUsable { return (keyFrame, .keyFrame) }
        if let best = moments.first { return (MomentRanking.rounded((best.start + best.end) / 2), .topMoment) }
        let peak: InterestLevel? = levels.max {
            $0.level == $1.level ? $0.start > $1.start : $0.level < $1.level
        }
        if let peak, peak.level > 0 { return (MomentRanking.rounded((peak.start + peak.end) / 2), .peakLevel) }
        return (MomentRanking.rounded(duration / 2), .middle)
    }
}
