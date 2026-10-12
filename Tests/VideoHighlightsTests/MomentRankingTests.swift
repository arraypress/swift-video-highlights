//
//  MomentRankingTests.swift
//  VideoHighlightsTests
//
//  Created by David Sherlock on 2026.
//

import Testing
@testable import VideoHighlights

/// Levels at `level` from `start` to `end`, in half-second segments.
private func levels(_ spans: [(Double, Double, Double)], duration: Double) -> [InterestLevel] {
    var result: [InterestLevel] = []
    var t: Double = 0
    while t < duration {
        let end: Double = min(duration, t + 0.5)
        let level: Double = spans.first { t >= $0.0 && t < $0.1 }?.2 ?? 0
        result.append(InterestLevel(start: t, end: end, level: level))
        t = end
    }
    return result
}

@Suite("Moment ranking")
struct MomentRankingTests {

    @Test("The score is the overlap-weighted mean, and the peak the highest level")
    func scoring() {
        let series = [InterestLevel(start: 0, end: 1, level: 2), InterestLevel(start: 1, end: 2, level: 8)]
        let whole = MomentRanking.score(from: 0, to: 2, levels: series)
        #expect(whole.mean == 5)
        #expect(whole.peak == 8)
        let quarter = MomentRanking.score(from: 0.5, to: 1.5, levels: series)
        #expect(quarter.mean == 5, "half of each segment")
        #expect(MomentRanking.score(from: 5, to: 6, levels: series).mean == 0, "nothing covers it")
    }

    @Test("Neighbouring highlights join; far ones and over-long joins stay apart")
    func joining() {
        let highlights: [ClosedRange<Double>] = [20...25, 10...14, 15...18, 40...45, 46...50]
        let joined = MomentRanking.clusters(of: highlights, joinGap: 2, maximumLength: 12)
        #expect(joined.map(\.span) == [10...18, 20...25, 40...50])
        #expect(joined.map(\.count) == [2, 1, 2])
        // A join that would pass the maximum starts a new cluster instead.
        let capped = MomentRanking.clusters(of: [0...5, 6...11, 12...17], joinGap: 2, maximumLength: 12)
        #expect(capped.map(\.span) == [0...11, 12...17])
    }

    @Test("A short window grows evenly, is pushed back inside the video, and a long one keeps its middle")
    func fitting() {
        #expect(MomentRanking.fitted(26...31, minimumLength: 15, maximumLength: 60, duration: 60) == 21...36)
        #expect(MomentRanking.fitted(1...4, minimumLength: 15, maximumLength: 60, duration: 60) == 0...15, "pushed off the start")
        #expect(MomentRanking.fitted(56...59, minimumLength: 15, maximumLength: 60, duration: 60) == 45...60, "pushed off the end")
        #expect(MomentRanking.fitted(0...100, minimumLength: 15, maximumLength: 30, duration: 200) == 35...65)
        #expect(MomentRanking.fitted(2...4, minimumLength: 15, maximumLength: 60, duration: 6) == 0...6, "never longer than the video")
    }

    @Test("Moments rank by mean level, never overlap, and stop at top")
    func ranking() {
        let duration: Double = 300
        let series = levels([(30, 40, 2), (100, 108, 9), (200, 205, 6)], duration: duration)
        let options = HighlightOptions(top: 2, minimumLength: 10, maximumLength: 60)
        let moments = MomentRanking.moments(highlights: [30...40, 100...108, 200...205], levels: series,
                                            duration: duration, options: options)
        #expect(moments.count == 2)
        #expect(moments.map(\.rank) == [1, 2])
        #expect(moments[0].start == 99 && moments[0].end == 109, "the level-9 moment, widened to 10 s")
        // The 5 s level-6 highlight widened to 10 s averages 3: above the
        // level-2 window, so it comes second. (Widening dilutes on purpose.)
        #expect(moments[1].start < 205 && moments[1].end > 200, "then the level-6 one")
        #expect(moments[1].score == 3)
        #expect(moments[0].score > moments[1].score)
    }

    @Test("Ties go to the earlier moment, so the answer never changes between runs")
    func ties() {
        let duration: Double = 100
        let series = levels([(10, 20, 5), (60, 70, 5)], duration: duration)
        let moments = MomentRanking.moments(highlights: [60...70, 10...20], levels: series, duration: duration,
                                            options: HighlightOptions(top: 1, minimumLength: 10, maximumLength: 30))
        #expect(moments.first?.start == 10)
    }

    @Test("A widened window that reaches a better one is dropped, not doubled up")
    func overlapIsSkipped() {
        let duration: Double = 100
        let series = levels([(40, 45, 9), (47, 49, 4)], duration: duration)
        let moments = MomentRanking.moments(highlights: [40...45, 47...49], levels: series, duration: duration,
                                            options: HighlightOptions(top: 3, minimumLength: 20, maximumLength: 60, joinGap: 1))
        #expect(moments.count == 1, "the second widens straight into the first")
    }

    @Test("No highlights is no moments, not an error")
    func nothing() {
        #expect(MomentRanking.moments(highlights: [], levels: levels([], duration: 60), duration: 60,
                                      options: HighlightOptions()).isEmpty)
    }
}
