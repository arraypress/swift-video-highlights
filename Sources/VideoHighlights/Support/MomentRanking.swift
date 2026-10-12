//
//  MomentRanking.swift
//  VideoHighlights
//
//  Created by David Sherlock on 2026.
//
//  From Apple's raw answer to "the best N clips". Apple's highlights are not a
//  top-N: on a 9-minute film it marked 50 of them, 2.5–10 s each, covering
//  30–58% of the running time. So they are joined into clip-length windows,
//  scored by the mean interest level across each window, and the best that
//  do not overlap are kept. Pure, so every rule is tested without a video.
//

/// Highlights + levels → ranked moments.
enum MomentRanking {

    /// The weighted mean and the peak level across `start…end`, from the
    /// level segments that overlap it. A window no segment covers scores 0.
    static func score(from start: Double, to end: Double, levels: [InterestLevel]) -> (mean: Double, peak: Double) {
        var weighted: Double = 0
        var covered: Double = 0
        var peak: Double = 0
        for level in levels {
            let overlap: Double = min(end, level.end) - max(start, level.start)
            guard overlap > 0 else { continue }
            weighted += level.level * overlap
            covered += overlap
            peak = max(peak, level.level)
        }
        guard covered > 0 else { return (0, 0) }
        return (weighted / covered, peak)
    }

    /// Highlights in time order, joined while the gap between them is at
    /// most `joinGap` and the joined span stays within `maximumLength`.
    /// Returns each cluster's span and how many highlights it joined.
    static func clusters(of highlights: [ClosedRange<Double>], joinGap: Double,
                         maximumLength: Double) -> [(span: ClosedRange<Double>, count: Int)] {
        let sorted: [ClosedRange<Double>] = highlights.sorted {
            $0.lowerBound == $1.lowerBound ? $0.upperBound < $1.upperBound : $0.lowerBound < $1.lowerBound
        }
        var result: [(span: ClosedRange<Double>, count: Int)] = []
        for highlight in sorted {
            if let last = result.last,
               highlight.lowerBound - last.span.upperBound <= joinGap,
               max(last.span.upperBound, highlight.upperBound) - last.span.lowerBound <= maximumLength {
                let joined: ClosedRange<Double> = last.span.lowerBound...max(last.span.upperBound, highlight.upperBound)
                result[result.count - 1] = (joined, last.count + 1)
            } else {
                result.append((highlight, 1))
            }
        }
        return result
    }

    /// A span widened or narrowed to fit `minimumLength…maximumLength` and
    /// the video: a short one grows evenly into the video around it (pushed
    /// back inside when it meets an end), a long one keeps its middle.
    static func fitted(_ span: ClosedRange<Double>, minimumLength: Double, maximumLength: Double,
                       duration: Double) -> ClosedRange<Double> {
        let length: Double = span.upperBound - span.lowerBound
        let centre: Double = (span.lowerBound + span.upperBound) / 2
        let wanted: Double = min(max(length, minimumLength), maximumLength, duration)
        var start: Double = centre - wanted / 2
        start = min(max(0, start), max(0, duration - wanted))
        return start...(start + wanted)
    }

    /// The best `options.top` moments, best first; ties go to the earlier
    /// one, so the same analysis always gives the same answer.
    static func moments(highlights: [ClosedRange<Double>], levels: [InterestLevel], duration: Double,
                        options: HighlightOptions) -> [HighlightMoment] {
        guard options.top > 0, duration > 0 else { return [] }
        let candidates: [(window: ClosedRange<Double>, mean: Double, peak: Double, count: Int)] =
            clusters(of: highlights, joinGap: options.joinGap, maximumLength: options.maximumLength).map { cluster in
                let window: ClosedRange<Double> = fitted(cluster.span, minimumLength: options.minimumLength,
                                                         maximumLength: options.maximumLength, duration: duration)
                let scored: (mean: Double, peak: Double) = score(from: window.lowerBound, to: window.upperBound,
                                                                 levels: levels)
                return (window, scored.mean, scored.peak, cluster.count)
            }
        let ranked = candidates.sorted {
            $0.mean == $1.mean ? $0.window.lowerBound < $1.window.lowerBound : $0.mean > $1.mean
        }
        var chosen: [(window: ClosedRange<Double>, mean: Double, peak: Double, count: Int)] = []
        for candidate in ranked where chosen.count < options.top {
            // Widening a short cluster can reach into a better one's window.
            let overlaps: Bool = chosen.contains {
                candidate.window.lowerBound < $0.window.upperBound && $0.window.lowerBound < candidate.window.upperBound
            }
            if !overlaps { chosen.append(candidate) }
        }
        return chosen.enumerated().map { index, item in
            HighlightMoment(rank: index + 1, start: rounded(item.window.lowerBound), end: rounded(item.window.upperBound),
                            score: rounded(item.mean), peak: rounded(item.peak), highlights: item.count)
        }
    }

    /// Hundredths: Apple's segments are about half a second, so more digits
    /// would only be noise.
    static func rounded(_ value: Double) -> Double { (value * 100).rounded() / 100 }
}
